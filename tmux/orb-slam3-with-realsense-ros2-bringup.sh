#!/usr/bin/env bash

# ===== 設定値 =====
SESSION="orb-slam3-with-realsense-ros2-bringup"         # 作成・接続する tmux セッション名
WORKDIR="$HOME/vision_ws/src/ORB-SLAM3-ROS2-Docker"  # 作業ディレクトリ（docker-compose.yml のある場所）
WORKDIR_IN_DOCKER="/root/colcon_ws"      # Docker内の作業ディレクトリ
CONTAINER="orb-slam3-ros2-docker-orb_slam3_22_humble-1"             # docker exec で入るコンテナ名
SLEEP=2                                 # docker 起動待ちのための待機秒数

# ===== 共通処理関数 =====
# 現在アクティブなペインに対して、共通の初期化コマンドを流し込む
# （待機 → 作業ディレクトリ移動 → コンテナに入る → ROS 環境読み込み → 画面クリア）
setup_pane () {
  tmux send-keys -t "$1" "sleep $SLEEP" C-m                          # 2秒待つ（Docker起動待ち）
  tmux send-keys -t "$1" "cd $WORKDIR" C-m                      # 作業ディレクトリへ移動
  tmux send-keys -t "$1" "while [ -z \"\$(docker ps -q -f name=$CONTAINER)\" ]; do echo '⏳ Waiting for container...'; sleep $SLEEP; done" C-m # コンテナが起動するまで待機
  tmux send-keys -t "$1" "docker exec -it $CONTAINER bash" C-m  # コンテナ内のシェルに入る
  tmux send-keys -t "$1" \
    "while [ ! -f $WORKDIR_IN_DOCKER/install/setup.bash ]; do echo '⏳ Waiting for build...'; sleep $SLEEP; done" C-m  # コンテナ起動待ち（install/setup.bashファイルが作成されるまで実行し続ける）
  tmux send-keys -t "$1" "source install/setup.bash" C-m        # ROS2 環境設定を読み込み
  tmux send-keys -t "$1" C-l                                    # 画面をクリアして見やすく
}

setup_ws_build () {
    tmux send-keys -t "$1" "./shell_scripts/ws_build.sh" C-m  # ワークスペースのビルドスクリプトを実行
}

# ===== セッション作成（既にあればスキップ）=====
tmux has-session -t "$SESSION" 2>/dev/null                       # 既存セッションの有無を確認
if [ $? != 0 ]; then                                             # 無ければ新規作成
    tmux new-session -d -s "$SESSION"                            # セッション作成（最初のペインが1つできる）

    # --- レイアウト作成 ---
    tmux split-window -h -t "$SESSION"         # 縦に分割（2つ目のペイン）
    tmux select-pane -R -t "$SESSION"          # 右の広いエリアにフォーカス

    # 右80%エリアをさらに分割して残り4ペイン作成
    tmux split-window -h -t "$SESSION"         # 横に2列（右側エリアをさらに縦分割）
    tmux select-pane -L -t "$SESSION"          # 左列へ戻る
    tmux split-window -v -t "$SESSION"         # 下に分割

    # --- ペイン番号にコマンドを当てはめ ---
    # ペイン .0：docker compose up
    tmux send-keys -t "$SESSION:.0" "cd $WORKDIR" C-m            # docker-compose.yml のある場所へ
    tmux send-keys -t "$SESSION:.0" "xhost local:" C-m           # X表示を許可（GUIアプリ利用時）
    tmux send-keys -t "$SESSION:.0" "docker compose down && sleep $SLEEP" C-m  # 既存のコンテナを停止してから再起動
    tmux send-keys -t "$SESSION:.0" "docker compose up --build" C-m      # コンテナ群を立ち上げ

    # ペイン .1：待機セッション
    setup_pane "$SESSION:.1"                                     # 共通初期化（コンテナに入って環境読み込み）
    setup_ws_build "$SESSION:.1"                                 # ワークスペースのビルドスクリプトを実行

    # ペイン .2：Realsenseカメラ起動
    setup_pane "$SESSION:.2"                                     # 共通初期化（コンテナに入って環境読み込み）
    tmux send-keys -t "$SESSION:.2" \
      "ros2 launch realsense2_camera rs_launch.py"               # Realsenseカメラ起動

    # ペイン .3：ORB-SLAM3 ROS2ラッパー起動
    setup_pane "$SESSION:.3"                                     # 共通初期化（コンテナに入って環境読み込み）
    tmux send-keys -t "$SESSION:.3" "clear" C-m                  # 画面クリア
    tmux send-keys -t "$SESSION:.3" \
      "ros2 launch orb_slam3_ros2_wrapper unirobot.launch.py"   # ORB-SLAM3 ROS2ラッパー起動
fi

# ===== セッションにアタッチ =====
tmux attach-session -t "$SESSION"
