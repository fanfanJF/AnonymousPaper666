
from extract import process_system


import os

import json
from tqdm import tqdm
import time


start=time.time()
for xml_file in tqdm(os.listdir('../data/mask-mutate/mutating_simu_models')): #processed_

    try:
       data = [line.strip('\n') for line in open(f'../data/mask-mutate/mutating_simu_models/{xml_file}/blockdiagram.xml', encoding='utf-8').readlines()]
    except:
        print(xml_file,'error')
        continue

    # has_system_sign = False
    # for line in data:
    #     if '<System>' in line:
    #         has_system_sign = True
    #         break

    if len(data) < 2:
        continue

    res=process_system(data)

    if res:
        nodes=res
        file_name = xml_file.replace('.xml','')
        with open(f'../data/mask-mutate/processed_mutation_data/{xml_file}.json', 'w', encoding='utf-8') as f:
            # f.write(json.dumps({'edges': total_edges}) + '\n')
            for k, v in nodes.items():
                f.write(json.dumps({k: v}) + '\n')





