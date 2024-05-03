

import json
import os
path = os.listdir('output')


useless_block = ["Reference", "Inport", "PMIOPort", "Outport"]
count=0
count2=0
f2 = open(f'../data/pretrain/mlm_corpus.txt', 'w', encoding='utf-8')

for file in path:
    with open(f'../data/pretrain/output/{file}') as f:
        for line in f.readlines():
            line = json.loads(line.strip())
            line = list(line.values())[0]
            line_new = []
            line_mask = []
            for block in line:
                if block == {}:
                    continue
                if block['BlockType'] in useless_block:
                    continue
                if not block.get('property'):
                    continue
                block_new = {}
                block_mask = {}
                for k,v in block.items():
                    if k!='Name' and k!='SID':
                        block_new[k] = v
                        if k=='property':
                            masked = {}
                            for property_name, value in v.items():
                                masked[property_name] = '<mask>'
                            block_mask[k] = masked
                        else:
                            block_mask[k] = v
                line_new.append(block_new)
                line_mask.append(block_mask)

            if len(line_new)>2:
                f2.write(str(line_new)+'\n')
                #print(line_mask)
                count+=1
            else:

                count2+=2

print(count)
print(count2)
f2.close()