
# Please install OpenAI SDK first: `pip3 install openai`
import os
import sys
from openai import OpenAI

def ai_translate(text: str):
    client = OpenAI(
        api_key=os.environ.get('DEEPSEEK_API_KEY'),
        base_url="https://api.deepseek.com"
    )

    response = client.chat.completions.create(
        model="deepseek-chat",
        messages=[
            {"role": "system", "content": "你是一个语言翻译专家，除非我特别说明，否则你将把我给你的内容翻译为中文(哪怕我给你的也是中文)，并且你只输出翻译后的内容，不要输出任何其他内容(比如你如何翻译，翻译的过程是什么等内容)。"},
            {"role": "user", "content": text},
        ],
        stream=False
    )

    return response.choices[0].message.content
    
def main():
    if len(sys.argv) > 2:
        # 多个参数分别翻译
        for idx, arg in enumerate(sys.argv[1:], 1):
            result = ai_translate(arg)
            print(f"{idx}: {result}")
    elif len(sys.argv) == 2:
        # 单个参数整体翻译
        print(ai_translate(sys.argv[1]))
    elif not sys.stdin.isatty():
        text = sys.stdin.read().strip()
        print(ai_translate(text))
    else:
        text = input("请输入要翻译的内容：")
        print(ai_translate(text))

if __name__ == "__main__":
    main()