
from transformers import AutoModel, AutoTokenizer, BertForMaskedLM
import torch
from tqdm import tqdm
import os
import json
import copy

import heapq
from transformers import RobertaTokenizer, RobertaForMaskedLM, pipeline


useless_block = ["Reference", "Inport", "PMIOPort", "Outport"]

model_path = '../data/saved_model'  # ./saved_model
model = RobertaForMaskedLM.from_pretrained(model_path)
tokenizer = RobertaTokenizer.from_pretrained(model_path)
mask_token = tokenizer.mask_token

text='{"propertyName":"-","propertyValue":"exit","original_propertyValue":"entry","targetSID":"6"}' \
     '{"propertyName":"-","propertyValue":"exit","original_propertyValue":"<mask>","targetSID":"-"}' \
     '{"propertyName":"-","propertyValue":"VehicleSpeed==up_th","original_propertyValue":"VehicleSpeed<up_th","targetSID":"20"}' \
     '{"propertyName":"-","propertyValue":"VehicleSpeed>=up_th","original_propertyValue":"VehicleSpeed<up_th","targetSID":"20"}' \
     '{"propertyName":"-","propertyValue":"VehicleSpeed>down_th","original_propertyValue":"<mask>(TWAIT,tick)[VehicleSpeed<=down_th]","targetSID":"22"}' \
     '{"propertyName":"-","propertyValue":"VehicleSpeed<=up_th","original_propertyValue":"after(TWAIT,tick)[VehicleSpeed>=up_th]","targetSID":"23"}'

texts='{"BlockType": "From", "Name": "From4", "property": {"GotoTag": "SL_Input"}}, {"BlockType": "From", "Name": "From6", ' \
      '"property": {"GotoTag": "SH_Input"}},{"BlockType": "Logic", "Name": "Operator","property": {"Operator": "<mask><mask>", "OutDataTypeStr": "boolean"}},'

inputs = tokenizer([texts], max_length=400, return_tensors='pt',
                   truncation=True)
# print([_.replace('Ġ','') for _ in tokenizer.tokenize(texts)])


mask_positions = []

for idx, token_id in enumerate(inputs['input_ids'].tolist()[0]):
    if token_id == tokenizer.mask_token_id:
        mask_positions.append(idx)
model.eval()
with torch.no_grad():
    logits = model(inputs['input_ids']).logits

    for i in range(len(mask_positions)):
        result = torch.topk(logits[0, mask_positions[i], :], dim=-1, k=10)
        indices = []
        values, indices = result[0].tolist(), result[1].tolist()

        for v, i in zip(values, indices):
            token = tokenizer.convert_ids_to_tokens([i])[0]
            print(token)
        print('        ')


