# terraform-practice

## 前提条件
1. AWSアカウントとAWS CLIが設定済み
2. Terraformが実行環境にインストール済み

## デプロイ手順
```bash
# LambdaコードのZIP化
cd lambda_function
zip -r ../lambda_function.zip .
cd ..

# Terraformを初期化
terraform init

# プランを確認
terraform plan

# デプロイ
terraform apply
```

## 削除手順
```bash
terraform destroy
```