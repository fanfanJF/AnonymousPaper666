


from extract import process_system

import os

import json
from tqdm import tqdm
import time


start=time.time()
for xml_file in tqdm(os.listdir('../data/pretrain/processed_data')):
    data = [line.strip('\n') for line in open(f'../data/pretrain/processed_data/{xml_file}', encoding='utf-8').readlines()]

    if len(data) < 2:
        continue

    res=process_system(data)

    if res:
        nodes=res
        file_name = xml_file.replace('.xml','')
        with open(f'./output/{file_name}.json', 'w', encoding='utf-8') as f:
            # f.write(json.dumps({'edges': total_edges}) + '\n')
            for k, v in nodes.items():
                f.write(json.dumps({k: v}) + '\n')

