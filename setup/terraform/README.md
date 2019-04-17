
## Requirements

* load-test-stateがprefixについたs3のバケットを用意していること
* `AWS_PROFILE=env ./generate-var.sh > terraform.tfvars`

## Usage

```
terraform apply
```

## 注意

stateの管理ちゃんとしてない。