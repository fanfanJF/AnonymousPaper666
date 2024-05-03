import json
import os
for file in os.listdir('./1/'):
    with open('./1/'+file, encoding='utf-8') as f, open('pro/'+file, 'w', encoding='utf-8') as f2:
        data = json.loads(f.read())
        dic={i+1:v for i,v in enumerate(data)}
        f2.write(json.dumps(dic))