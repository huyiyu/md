# 代码上线流程

## 功能测试流程
> ***开发人员自测*** && 测试人员根据需求号在本地将系统运行起来,做最简单功能测试,必须保证所有功能测试,边界测试没有问题

## 合并流程
### Github Flow(公司目前流程)
1. 所有人 fork 一份远程仓库,
2. 发起合并时,同名分支合并,冲突通过本地或远程 `merge`解决,
3. 一段时间后更新中心仓库,到自己远程派生库然后本地`git pull`更新代码
4. 重复1
### GitLab Flow
1. 不 fork 远程仓库,每个人没有中心远程代码, 直接 clone 中心仓库代码
2. 开发阶段使用 feat/fix/docs/style + [需求] + [姓名] 等分支名称去开发,
3. 测试流程提前,必须在所有功能测试/边界测试符合条件之后,才能进行代码评审,否则没有任何意义(***简化开发部署流程,让测试人员能轻易把一套系统跑起来***)
4. 测试通过后,[处理冲突整理提交历史](#提供清晰的git提交历史),提交到 release 分支,由负责 review 的人去提出意见编写相关的review 意见(***严格把关,宁可不上,不可放过***)
5. 测试人员在release 集成测试,稳定后发布测试环境直到可以合并主版本上线 打tag
## 代码评审
### 提供清晰的commit message 和change log
* 参考阮一峰博客: https://www.ruanyifeng.com/blog/2016/01/commit_message_change_log.html
* github 指定 ChangeLog 规范:https://docs.gitlab.com/ee/development/changelog.html
### 提供清晰的代码内容

1. 使用统一的代码风格约束,引入统一规范[google-style](.google-style.xml)
2. 修改代码时不提供没有意义的内容(换行,空格,未使用的import)
3. ***提交代码之前自查***,如果你自己都不为自己的代码负责,谁来为你的代码负责
4. 必要的地方写清楚注释
5. ***多阅读开源框架***,包括但不限于 spring,spring boot，mybatis,tomcat,netty ...

### 提供清晰的git提交历史
1. 开发前请设置好个人姓名和工作邮箱
```bash
# 开发前git 设置
git config --global user.name *** # 中文姓名
git config --global user.email *** # 工作邮箱
```
2. 每个人从develop checkout 一个分支出来叫 feat-XXX,fix-XXX ,***不允许多人使用相同的分支*** 命令 `git checkout -b fix-xxx develop` 此时分支内容和develop 一模一样
3. 编写代码,该过程 ***不要有 merge 其他分支的操作, 忘记 merge 命令*** 可以按个人习惯 commit
4. 如果需要更新develop上最新的代码可以 `git rebase develop` 
   1. 需要处理冲突时 rebase 会显示冲突 此时正常处理冲突,`git add .;git rebase --continue`即可解决, ***禁止使用 merge 处理更新***
   2. 不需要处理冲突会直接结束,结束后 采用 tig 或 git log --oneline 查看一下提交记录是否与自己所想一致
5. 功能开发结束之后,使用`git rebase -i [commit id]` 命令将多个自己的 commit 合并成一个,并推送到远程分支`git push ` `git rebase -i`的使用建议百度，这里整理了一下自己的简单理解
   1. [commit id] 填写的是你一开始从 dev 切出来的 git commit 的节点 会显示如下
   2. 自身提交合并后,git rebase develop 更新最新的内容 处理冲突参考 4.2
   3. 第一次推送会让你设置跟随的远程分支,一般情况下远程分支和本地分支同名 `git push --set-upstream origin fix-XXX`
   4. 如果远程分支已经推送并且提交了多个commit，请强行推送分支  `git push -f`
6. 提交后的预期结果是fix-XXX分支领先develop分支一个commit 如果没有达到预期结果请咨询Pro-Gits,
7. 在页面上发起合并请求,点击merge request
   1. 提交之前检查内容 是否有无意义空行/import *等不符合规范的内容
   2. 提交信息包括但不限于 更新环境变量，更新的数据库脚本，更新的内容说明，注意事项, 开发者，关注者
   3. 提交后请 ***立即*** 通知相关人员 code review 不允许自己偷偷合并
8. 目前 develop 分支和 master 分支已经不允许主动push 需要push 请通过gitlab 发起合并请求
```bash
pick 2dfcdb5 update README.md.
pick 3a22696 update README.md.
pick ab71cc3 update README.md.
# Rebase 6797f06..ab71cc3 onto 6797f06
#
# Commands:
#  p, pick = use commit
#  r, reword = use commit, but edit the commit message
#  e, edit = use commit, but stop for amending
#  s, squash = use commit, but meld into previous commit
#  f, fixup = like "squash", but discard this commit's log message
#  x, exec = run command (the rest of the line) using shell
#
# These lines can be re-ordered; they are executed from top to bottom.
#
# If you remove a line here THAT COMMIT WILL BE LOST.
#
# However, if you remove everything, the rebase will be aborted.
#
# Note that empty commits are commented out
``` 
## 参考
1. [编写commit message 和 change log](https://www.ruanyifeng.com/blog/2016/01/commit_message_change_log.html
)
2. [pro-git](https://www.progit.cn/#_%E5%88%86%E5%B8%83%E5%BC%8F%E5%B7%A5%E4%BD%9C%E6%B5%81%E7%A8%8B)