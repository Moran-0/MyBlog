---
title: Hexo文档
date: 2025-11-01 14:16:14
tags:
- Hexo
cover: /img/cover/blue_archive-underwear.jpg
---

# Hexo文档



## 什么是Hexo？

Hexo 是一个快速、简洁且高效的博客框架。 Hexo 使用 [Markdown](http://daringfireball.net/projects/markdown/)（或其他标记语言）解析文章，在几秒内，即可利用靓丽的主题生成静态网页。



## Hexo命令

安装以后，可以使用以下两种方式执行 Hexo：

1. `npx hexo <command>`
2. Linux 用户可以将 Hexo 所在的目录下的 `node_modules` 添加到环境变量之中即可直接使用 `hexo <command>`：

```bash
echo 'PATH="$PATH:./node_modules/.bin"' >> ~/.profile
```



### 创建写作

你可以执行下列命令来创建一篇新文章或者新的页面。

```bash
$ hexo new [layout] <title>
```

`post`是默认的`布局`，但你也可以提供自己的布局。 您可以通过编辑 `_config.yml` 中的 `default_layout` 设置来更改默认布局。



### 布局（Layout）

Hexo 有三种默认布局：`post`、`page` 和 `draft`。 每个布局创建的文件会被保存到不同的路径。 新创建的帖子被保存到 `source/_post` 文件夹。

| 布局    | 路径             |
| :------ | :--------------- |
| `post`  | `source/_posts`  |
| `page`  | `source`         |
| `draft` | `source/_drafts` |



### 文件名称

默认情况下，Hexo 使用帖子标题作为其文件名。 您可以编辑 `_config.yml` 中的 `new_post_name` 设置去更改默认文件名。 例如， `:year-:month-:day-:title.md` 将在文件名前加上创建日期。 你可以使用以下占位符：

| 占位符     | 描述                                |
| :--------- | :---------------------------------- |
| `:title`   | 标题（小写，空格将会被替换为短杠）  |
| `:year`    | 建立的年份，比如， `2015`           |
| `:month`   | 建立的月份（有前导零），比如， `04` |
| `:i_month` | 建立的月份（无前导零），比如， `4`  |
| `:day`     | 建立的日期（有前导零），比如， `07` |
| `:i_day`   | 建立的日期（无前导零），比如， `7`  |

### 草稿

之前，我们在提到了 Hexo 中的一个特殊的布局：`draft`。 使用此布局初始化的帖子将被保存到 `source/_drafts` 文件夹中。 您可以使用 `发布` 命令将草稿移动到 `source/_posts` 文件夹。 `publish` 工作方式类似于 `new` 命令。

```
$ hexo publish [layout] <title>
```

默认情况下不显示草稿 您可以在运行 Hexo 时添加 `--draft` 选项或在 `_config.yml` 启用 `render_draft` 设置来渲染草稿。

### 脚手架

在新建文章时，Hexo 会根据 `scaffolds` 文件夹内相对应的文件来建立文件。 例如：

```cmd
$ hexo new photo "My Gallery"
```

在执行这行指令时，Hexo 会尝试在 `scaffolds` 文件夹中寻找 `photo.md`，并根据其内容建立文章。 以下是您可以在模版中使用的变量：

| 占位符   | 描述         |
| :------- | :----------- |
| `layout` | 布局         |
| `title`  | 标题         |
| `date`   | 文件建立日期 |



## 格式 Front-matter



Front-matter 是文件开头的 YAML 或 JSON 代码块，用于配置写作设置。 以 YAML 格式书写时，Front-matter 以三个破折号结束；以 JSON 格式书写时，Front-matter 以三个分号结束。

**YAML**

```yaml
---
title: Hello World
date: 2013/7/13 20:46:25
---
```

**JSON**

```yaml
"title": "Hello World",
"date": "2013/7/13 20:46:25"
;;;
```

### 设置 & 默认值

| 设置              | 描述                                                         | 默认值                                                       |
| :---------------- | :----------------------------------------------------------- | :----------------------------------------------------------- |
| `layout`          | 布局                                                         | [`config.default_layout`](https://hexo.io/docs/configuration#Writing) |
| `title`           | 标题                                                         | 文章的文件名                                                 |
| `date`            | 建立日期                                                     | 文件建立日期                                                 |
| `updated`         | 更新日期                                                     | 文件更新日期                                                 |
| `comments`        | 开启文章的评论功能                                           | `true`                                                       |
| `tags`            | 标签（不适用于分页）                                         |                                                              |
| `categories`      | 分类（不适用于分页）                                         |                                                              |
| `permalink`       | 覆盖文章的永久链接. 永久链接应该以 `/` 或 `.html` 结尾       | `null`                                                       |
| `excerpt`         | 纯文本的页面摘要。 使用 [该插件](https://hexo.io/zh-cn/docs/tag-plugins#文章摘要和截断) 来格式化文本 |                                                              |
| `disableNunjucks` | 启用时禁用 Nunjucks 标签 `{{ }}`/`{% %}` 和 [标签插件](https://hexo.io/zh-cn/docs/tag-plugins) 的渲染功能 | false                                                        |
| `lang`            | 设置语言以覆盖 [自动检测](https://hexo.io/zh-cn/docs/internationalization#路径) | 继承自 `_config.yml`                                         |
| `published`       | 文章是否发布                                                 | 对于 `_posts` 下的文章为 `true`，对于 `_draft` 下的文章为 `false` |

#### 布局

根据 `_config.yml` 中 [`default_layout`](https://hexo.io/zh-cn/docs/configuration#文章) 的设置，默认布局是 `post` 。 当文章中的布局被禁用(`layout: false`)，它将不会使用主题处理。 然而，它仍然会被任何可用的渲染引擎渲染：如果一篇文章是用 Markdown 写的，并且安装了 Markdown 渲染引擎（比如默认的 [hexo-renderer-marked](https://github.com/hexojs/hexo-renderer-marked))，它将被渲染成HTML。

除非通过 `disableNunjucks` 设置或 [渲染引擎](https://hexo.io/zh-cn/api/renderer#禁用-Nunjucks-标签) 禁用，否则无论布局如何，[标签插件](https://hexo.io/zh-cn/docs/tag-plugins) 总是被处理。

#### 分类和标签

只有文章支持分类和标签。 分类按顺序应用于文章，从而形成分类和子分类的层次结构。 标签是在相同的层次结构上定义的，因此它们的出现顺序不重要。

**示例**

```yaml
categories:
  - Sports
  - Baseball
tags:
  - Injury
  - Fight
  - Shocking
```

如果你想应用多个分类层次结构，请使用一个名称列表而不是一个单个名称。 如果 Hexo 在帖子上看到像这种方式定义的分类，它会将该帖子的每个分类视为其自己的独立层次结构。

**示例**

```yaml
categories:
  - [Sports, Baseball]
  - [MLB, American League, Boston Red Sox]
  - [MLB, American League, New York Yankees]
  - Rivalries
```



## 部署

在本教程中，我们使用 [GitHub Actions](https://docs.github.com/zh/actions) 部署 GitHub Pages。 此方法适用于公开或私人储存库. 若你不希望将源文件夹上传到 GitHub，请参阅 [一键部署](https://hexo.io/zh-cn/docs/github-pages#一键部署)。

1. 建立名为 ***username.github.io***的储存库。 若之前已将 Hexo 上传至其他储存库，将该储存库重命名即可。
2. 将 Hexo 文件夹中的文件 push 到储存库的默认分支。 默认分支通常名为**main**，旧一点的储存库可能名为**master**。

- 将 `main` 分支 push 到 GitHub：

  ```bash
  $ git push -u origin main
  ```

- 默认情况下 `public/` 不会被上传(也不该被上传)，确保 `.gitignore` 文件中包含一行 `public/`。 整体文件夹结构应该与 [示例储存库](https://github.com/hexojs/hexo-starter) 大致相似。

1. 使用 `node --version` 指令检查你电脑上的 Node.js 版本。 记下主要版本（例如，`v20.y.z`）
2. 在储存库中前往 **Settings** > **Pages** > **Source** 。 将 source 更改为 **GitHub Actions**，然后保存。
3. 在储存库中建立 `.github/workflows/pages.yml`，并填入以下内容 (将 `20` 替换为上个步骤中记下的版本)：

```yaml
.github/workflows/pages.ymlname: Pages

on:
  push:
    branches:
      - main # default branch

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
          # If your repository depends on submodule, please see: https://github.com/actions/checkout
          submodules: recursive
      - name: Use Node.js 20
        uses: actions/setup-node@v4
        with:
          # Examples: 20, 18.19, >=16.20.2, lts/Iron, lts/Hydrogen, *, latest, current, node
          # Ref: https://github.com/actions/setup-node#supported-version-syntax
          node-version: "20"
      - name: Cache NPM dependencies
        uses: actions/cache@v4
        with:
          path: node_modules
          key: ${{ runner.OS }}-npm-cache
          restore-keys: |
            ${{ runner.OS }}-npm-cache
      - name: Install Dependencies
        run: npm install
      - name: Build
        run: npm run build
      - name: Upload Pages artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: ./public
  deploy:
    needs: build
    permissions:
      pages: write
      id-token: write
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```

1. 部署完成后，前往 *username*.github.io 查看网页。

若你使用了一个带有 `CNAME` 的自定义域名，你需要在 `source/` 文件夹中新增 `CNAME` 文件。 [更多信息](https://docs.github.com/zh/pages/configuring-a-custom-domain-for-your-github-pages-site/managing-a-custom-domain-for-your-github-pages-site)

### 项目页面

如果您希望在 GitHub 上有一个项目页面：

1. 导航到 GitHub 上的存储库。 转到 **Settings** 选项卡。 建立名为 `<repository 的名字>` 的储存库，这样你的博客网址为 `<你的 GitHub 用户名>.github.io/<repository 的名字>`，repository 的名字可以任意，例如 blog 或 hexo。
2. 编辑你的 `_config.yml`，将 `url:` 更改为 `<你的 GitHub 用户名>.github.io/<repository 的名字>`。
3. 在 GitHub 仓库的设置中，导航至 **Settings** > **Pages** > **Source** 。 将 source 更改为 **GitHub Actions**，然后保存。
4. Commit 并 push 到默认分支上。
5. 部署完成后，前往 *username*.github.io/*repository* 查看网页。
