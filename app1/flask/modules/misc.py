import os
import json
import hashlib

# conf_dir
current_dir = os.path.dirname(__file__)
conf_path = os.path.join(current_dir, "../conf/common.json")
flask_path = os.path.join(current_dir, "../conf/conf.json")

def generate_hash(indata,salt):
    text = (indata + salt).encode("utf-8")
    result = hashlib.sha512(text).hexdigest()
    return result

def get_flask_json():
    with open(flask_path, "r") as fp:
        dict_flask = json.load(fp)
        return dict_flask


def get_com_json():
    with open(conf_path, "r") as fp:
        dict_com = json.load(fp)
        return dict_com


def get_dir_tree(path, list_tree):
    """
    pathのディレクトリ下を再帰的にlist_treeに辞書として格納する.
    """
    abspath = os.path.abspath(path)
    basename = os.path.basename(abspath)
    key = basename
    dict = {}
    dict[key] = []
    for content in os.listdir(abspath):
        joinpath = os.path.join(path, content)
        if (os.path.isdir(joinpath)):
            get_dir_tree(joinpath, dict[key])
        else:
            dict[key].append(content)
    # add
    list_tree.append(dict)


if __name__ == "__main__":
    root = "./"
    list_root_tree = []
    get_dir_tree(root, list_root_tree)
