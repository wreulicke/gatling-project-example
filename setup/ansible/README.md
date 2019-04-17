
## What is this?

packerで作ったAMIを使って
terraformでautoscaling groupを作った後に
負荷試験のシナリオを弄った時に使うスクリプト

## Usage

```bash
# TagのNameがload-testのインスタンスを引っ張ってきて適用する。
# AWS_PROFILEとprivate-keyを書き換えて適用。
# リポジトリルートで実行した例
$ AWS_PROFILE=env ansible-playbook -i setup/ansible/inventory.sh --private-key="~/.ssh/your.pem" setup/ansible/setup.yml
```