

import os
import json

file_idx = 0

for file in os.listdir('../data/pretrain/raw_data/'):
    for f in os.listdir(f'../data/pretrain/raw_data/{file}'):
        if '.xml' in f:
            print('s', f'../data/pretrain/raw_data/{file}/{f}')
            file_idx += 1
            with open(f'../data/pretrain/raw_data/{file}/{f}', 'r', encoding='utf-8') as f1,\
                open(f'../data/pretrain/processed_data/{file}-{f}.xml', 'w', encoding='utf-8') as f2:
                # if len([line for line in f.readlines()]) < 2:
                #     continue
                for line in f1.readlines():
                    f2.write(line)

        else:
            if os.path.isdir(f'../data/pretrain/raw_data/{file}/{f}/'):
                for subf in os.listdir(f'../data/pretrain/raw_data/{file}/{f}/'):
                    if 'xml' in subf:
                        print(f'../data/pretrain/raw_data/{file}/{f}/{subf}')
                        file_idx += 1

                        with open(f'../data/pretrain/raw_data/{file}/{f}/{subf}', 'r', encoding='utf-8') as f1, \
                                open(f'../data/pretrain/processed_data/{str(file)}-{str(f)}.xml', 'w', encoding='utf-8') as f2:

                            for line in f1.readlines():
                                f2.write(line)



print(file_idx)



