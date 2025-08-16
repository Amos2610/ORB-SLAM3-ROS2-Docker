# ORB-SLAM3-ROS2-Docker Setup Guide

このリポジトリは **ORB-SLAM3 を ROS2 上で動作させるための Docker 環境** を提供します。  
以下の手順でセットアップと動作確認が可能です。

---

## 1. 依存環境

- Ubuntu 20.04 / 22.04  
- Docker  
- Docker Compose v2  
- tmux（自動化起動を使う場合）

---

## 2. リポジトリの取得

```bash
cd <your_directory>
git clone https://github.com/your-org/ORB-SLAM3-ROS2-Docker.git
cd ORB-SLAM3-ROS2-Docker
git submodule update --init --recursive
```

---

## 3. コンテナのビルドと起動

### 方法A: 通常の方法（tmux を使わない）

```bash
# ビルド & 起動
docker compose up --build

# コンテナに入る
docker exec -it orb-slam3-ros2-docker-orb_slam3_22_humble-1 bash

# ワークスペースのビルド
sh shell_scripts/ws_build.sh
```

---

### 方法B: tmux を使った方法（推奨）

自動で **ビルド → setup → Realsense 起動 → ORB-SLAM3 起動** を行います。

```bash
cd <your_directory>/ORB-SLAM3-ROS2-Docker
./tmux/orb-slam3-with-realsense-ros2-bringup.sh
```

このスクリプトは以下を行います:

* **ペイン1**: コンテナ起動
* **ペイン2**: ワークスペースビルド & setup
* **ペイン3**: RealSense カメラ起動

  ```bash
  ros2 launch realsense2_camera rs_launch.py
  ```
* **ペイン4**: ORB-SLAM3 起動

  ```bash
  ros2 launch orb_slam3_ros2_wrapper unirobot.launch.py
  ```

---

## 4. よくある問題

### `Permission denied` が出る場合

Docker の実行権限がユーザに付与されていない可能性があります。以下を実行してください:

```bash
# ユーザを docker グループに追加
sudo usermod -aG docker $USER

# グループを反映（再ログインまたは再起動が必要）
newgrp docker
```

これで `sudo` を付けずに `docker compose up` を実行できるようになります。

### submodule が空の場合

```bash
git submodule update --init --recursive
```