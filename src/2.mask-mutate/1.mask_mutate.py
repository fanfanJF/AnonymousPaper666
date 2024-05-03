import random

# -*- coding: utf-8 -*-
from transformers import AutoModel, AutoTokenizer, BertForMaskedLM
import torch
from tqdm import tqdm
import os
import json
import copy

import heapq
from transformers import RobertaTokenizer, RobertaForMaskedLM, pipeline


useless_block = ["Reference", "Inport", "PMIOPort", "Outport"]

model_path = '../data/saved_model'
model = RobertaForMaskedLM.from_pretrained(model_path)
tokenizer = RobertaTokenizer.from_pretrained(model_path)
mask_token = tokenizer.mask_token

property_name_value_map = {
                           'Operator':{'RelationalOperator':['<','>','==','~=','<=','>='],
                                                 'Logic':['AND', 'OR', 'NAND', 'NOR', 'NNOR', 'NOT']} ,
                           'SampleTime':[0, -1, 2, 1],
                           }

def filter_info(text):
    res=[]
    for block in text:
        if 'property' not in list(block.keys()):
            continue
        if block['BlockType'] in useless_block:
            continue
        block_new = {}
        for k, v in block.items():
            if k == 'property' or k == 'SID' or k=='BlockType':
                block_new[k] = v
        res.append(block_new)

    return res

def relationaloperator_string_symbol_mapping(string):
    string=string.lower().replace(';','').replace('&','').replace(',','')
    mapping = {'lt':'<', 'gt':'>', 'ge':'≥', 'le':'≤', 'eq':'=', 'ne':'≠'}

    if mapping.get(string):
        res=mapping[string]
    else:
        res=string
    return res



def create_mask(info):
    all_masked_infos = []
    info_ori = [copy.deepcopy(block) for block in info]

    def masking(block, info, i):
        block_copy = copy.deepcopy(block)
        length = len(tokenizer.tokenize(val))
        block_copy['property'][name] = mask_token * length
        info[i] = block_copy
        return info

    for i in range(len(info)):
        block=info[i]
        blocktype = block["BlockType"]
        properties = block['property']
        SID= block.get('SID')
        for name, val in properties.items():

            if 'operator' in name.lower() and blocktype=='RelationalOperator':
                val=relationaloperator_string_symbol_mapping(val)

            res=masking(block, info, i)
            all_masked_infos.append((res, blocktype, name, SID))
            info = info_ori.copy()

    return all_masked_infos



def mutation(text, property_name):

    inputs = tokenizer([text], max_length=400, return_tensors='pt',
                       truncation=True)
    mask_positions = []

    for idx, token_id in enumerate(inputs['input_ids'].tolist()[0]):
        if token_id == tokenizer.mask_token_id:
            mask_positions.append(idx)

    limited_vocab = None #property_name_value_map.get(property_name)

    if limited_vocab:
        # limited_vocab
        # for tokens in limited_vocab:
        #     print(tokens)
        #     length = len(tokenizer.tokenize(tokens))
        #     if length==len(mask_positions):
        #         pass
        limited_vocab_ids = [tokenizer.convert_tokens_to_ids(token) for token in limited_vocab]
        #print(limited_vocab_ids)
    else:
        limited_vocab_ids = None

    model.eval()
    with torch.no_grad():
        logits = model(inputs['input_ids']).logits

        all_tokens = []
        all_scores = []

        for i in range(len(mask_positions)):
            topk = 10
            if limited_vocab_ids:
                topk = len(limited_vocab_ids) if topk>=len(limited_vocab_ids) else topk
                result = torch.topk(logits[0, mask_positions[i], limited_vocab_ids], dim=-1, k=topk)
                indices = []
                values, indices_ = result[0].tolist(), result[1].tolist()
                for i in indices_:
                    indices.append(limited_vocab_ids[i])

            else:
                result = torch.topk(logits[0, mask_positions[i]], dim=-1, k=topk)
                values, indices = result[0].tolist(), result[1].tolist()

            tokens = []
            scores = []
            for v, i in zip(values, indices):
                token = tokenizer.convert_ids_to_tokens([i])[0]
                tokens.append(token)
                scores.append(v)
                # print(f'token:{token},score:{v}')

            all_tokens.append(tokens)
            all_scores.append(scores)
    return all_tokens, all_scores



def find_top_tokens(all_tokens, all_scores, topk=2):
    #print(all_tokens)
    token_combinations = list(zip(*all_tokens))
    score_combinations = [sum(score_group) for score_group in zip(*all_scores)]

    tokens = []
    for tok in token_combinations:
        token = ''.join(tok)
        tokens.append(token)

    return [item.replace('Ġ', '') for item in tokens[:topk]], score_combinations[:topk]


successful_mautated_blocks = 0
successful_mautated_mutants = 0
for xml_file in tqdm(os.listdir('../data/mask-mutate/processed_mutation_data')):
    xml = xml_file.replace('.json','')
    if 'tust' not in xml:
        continue

    with (open(f'../data/mask-mutate/processed_mutation_data/{xml_file}', 'r', encoding='utf-8') as f,
          open(f'../data/mask-mutate/mutation_output/{xml}_mut.json', 'w', encoding='utf-8') as f2):
        for line in f.readlines():
            line=json.loads(line.strip())
            info=filter_info(list(line.values())[0])
            successful_mautated_blocks+=len(info)

            if info==[]:
                continue

            ori_info = copy.deepcopy(info)

            masked_info = create_mask(info)

            masked_sequence = [_[0] for _ in masked_info]
            correspond_name = [_[1] for _ in masked_info]
            correspond_sid = [_[2] for _ in masked_info]


            for (masked_sequence, blocktype, name, sid) in masked_info:
                print(name)
                all_tokens, all_scores = mutation(str(masked_sequence), name)

                for ori_block in ori_info:
                    if ori_block['SID'] == sid:
                        ori_property_value = ori_block['property'][name]

                topk_tokens, score = find_top_tokens(all_tokens, all_scores, topk=5)

                if name == 'GotoTag':
                    topk_tokens = topk_tokens[:3]
                if name == 'Value':
                    topk_tokens = topk_tokens[:3]

                # if name == 'SaturateOnIntegerOverflow':
                #     continue
                if name == 'Threshold':
                    continue

                no_repated_pred_tokens = []
                for pred_token in topk_tokens:
                    if name == 'SaturateOnIntegerOverflow':
                        if pred_token != 'off' and pred_token != 'on':
                            continue

                    restricted_vals = property_name_value_map.get(name)
                    if restricted_vals and pred_token not in restricted_vals:
                        continue

                    # if name == 'Threshold':
                    #     try:
                    #         pred_token = eval(pred_token)
                    #     except:
                    #         continue
                    #
                    #     if float(pred_token)==float(ori_property_value):
                    #         continue

                    if name == 'Value':
                        try:
                            pred_token = eval(pred_token)
                        except:
                            continue

                        try:
                            if float(pred_token)==float(ori_property_value):
                                continue
                        except:
                            continue

                    if name == 'SampleTime':
                        try:
                            pred_token = eval(pred_token)
                        except:
                            continue

                        if float(pred_token)==float(ori_property_value):
                            continue

                    if name == 'Gain':
                        try:
                            float_value = float(pred_token)
                        except ValueError:
                            continue


                    if pred_token == ori_property_value:
                        continue
                    elif pred_token in no_repated_pred_tokens:
                        continue
                    else:
                        no_repated_pred_tokens.append(pred_token)

                if property_name_value_map.get(name):
                    if name == 'Operator':
                        add_token = random.sample(property_name_value_map[name][blocktype], 2)
                    else:
                        add_token = random.sample(property_name_value_map[name], 2)
                    for add_tok in add_token:
                        if add_tok not in no_repated_pred_tokens and add_token != ori_property_value:
                            no_repated_pred_tokens.append(add_tok)

                successful_mautated_mutants+=len(no_repated_pred_tokens)
                final_pred_tokens = []
                for token in no_repated_pred_tokens:
                    if token != ori_property_value and str(token) != str(ori_property_value):
                        final_pred_tokens.append(token)

                if final_pred_tokens != []:
                    f2.write(json.dumps([final_pred_tokens, name, sid, ori_property_value])+'\n')


print(f'num of successful_mutated_blocks: {successful_mautated_blocks}')
print(f'num of successful_mutants: {successful_mautated_mutants}')

