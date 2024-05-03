import json
import os
for file in os.listdir('./raw/'):
    with open('./raw/'+file, encoding='utf-8') as f, open(file, 'w', encoding='utf-8') as f2:
        data = json.loads(f.read())
        dic={i+1:v for i,v in enumerate(data)}
        f2.write(json.dumps(dic))