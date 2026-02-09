import requests
from bs4 import BeautifulSoup
import os

def get_html(url):
    # 自定义 header 假装不是一个爬虫程序
    headers = {
        "User-Agent": "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:147.0) Gecko/20100101 Firefox/147.0"
    }
    response = requests.get(url, headers=headers)
    if response.ok is False:
            print(f"请求失败， 状态码：{response.status_code}")
            return None
    # 这里必须根据实际规定格式
    response.encoding = 'utf-8'
    return response.text

def get_minzu_info(url):
    minzu_html = get_html(url)
    if minzu_html is None:
        return None
    minzu_soup = BeautifulSoup(minzu_html, "html.parser")
    if minzu_soup is None:
        return None
    minzu_info = minzu_soup.find("div", attrs={"class":"pd15"})
    if minzu_info is None:
        return None
    return minzu_info.text

def main():
    print("Hello from web-crawler!")

    prefix = "https://www.neac.gov.cn/"
    home_html = get_html(f"{prefix}/seac/ztzl/zgmzjs/index.shtml")
    soup = BeautifulSoup(home_html, "html.parser")

    # 获取官方承认的所有民族的列表
    mz_list = soup.find("div", class_="mz_list")
    mz_list_li  = mz_list.find_all("li")

    for li in mz_list_li:
        a_tag = li.find("a")
        href = a_tag["href"]

        mz_cn_name = a_tag.text
        print(f"正在抓取 {mz_cn_name} 民族的信息...")
        os.makedirs(f"output/{mz_cn_name}/", exist_ok=True)

        mz_url_prefix = href.rsplit('/', 1)[0] + '/'
        
        url_suffix_dict_list = ({"/gk.shtml": "基本信息"},
                                {"/lsyg.shtml": "历史沿革"},
                                {"/fswh.shtml": "风俗习惯", "/fsxg.shtml": "风俗习惯"},
                                {"/fzxz.shtml": "发展状况", "/fzzk.shtml": "发展状况", "/fzsh.shtml": "发展社会"})

        for url_suffix_dict in url_suffix_dict_list:
            flag = False
            for suffix, title in url_suffix_dict.items():
                target_url = f"{prefix}{mz_url_prefix}{suffix}"
                info = get_minzu_info(target_url)
                if info is None:
                    continue
                else:
                    flag = True
                
                with open(f"output/{mz_cn_name}/{title}.txt", "w", encoding="utf-8") as file:
                    file.write(info)
                if flag is True:
                    break
            if flag is False:
                print(f"error: 或许 url -> {target_url} 错误了?")
                exit(1)

if __name__ == "__main__":
    main()
