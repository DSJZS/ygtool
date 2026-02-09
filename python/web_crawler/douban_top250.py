import requests
from bs4 import BeautifulSoup

def main():
    print("Hello from web-crawler!")

    # 自定义 header 假装不是一个爬虫程序
    headers = {
        "User-Agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0"
    }

    top = 1
    for start_num in range(0, 250, 25):
        response = requests.get(f"https://movie.douban.com/top250?start={start_num}&filter=", headers=headers)

        if response.ok is False:
            print(f"请求失败， 状态码：{response.status_code}")
            return
        
        html = response.text
        soup = BeautifulSoup(html, "html.parser")

        all_titles = soup.find_all("span", attrs={"class": "title"})

        for title in all_titles:
            title_string = title.string
            if "/" not in title_string:
                print(f"top {top}：{title_string}")
                top += 1

if __name__ == "__main__":
    main()
