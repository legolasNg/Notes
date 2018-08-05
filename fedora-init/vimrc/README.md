# Vim init

## 安装vim

```bash
sudo dnf install vim
```

## 安装vim-plug

```bash
curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
```

## 安装依赖

```bash
sudo dnf install ctag
```

## 复制配置文件

```bash
curl -o ~/.vimrc https://raw.githubusercontent.com/legolasng/notes/master/fedora-init/vimrc/.vimrc
```

## 安装插件

```bash
# 启动vim
vim

# 在vim中输入:PlugInstall指令来安装插件
```