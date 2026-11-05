---
title: "Virtual Tokyo Trip Planner - Project Index"
type: "index"
status: "active"
tags:
  - project-index
  - navigation
  - documentation
links:
  - "./README.md"
  - "./planning/presentation-schedule.md"
  - "./planning/milestone-1-progress.md"
  - "./planning/tokyo-trip-plan-2026.md"
  - "./roblox-world/object-deployment-plan.md"
  - "./roblox-world/room-layout-design.md"
  - "./roblox-world/room-floor-design-spec.md"
  - "./roblox-world/objects/room-spatial-dimension-spec.md"
  - "./roblox-world/objects/room-wall-design-spec.md"
  - "./roblox-world/objects/info-board-featured-spots.md"
  - "./roblox-world/objects/info-board-specific-shops.md"
  - "./roblox-world/objects/info-board-accommodation.md"
  - "./roblox-world/objects/workspace-hierarchy.md"
  - "./roblox-world/objects/zone-c-omoideyokocho-design.md"
  - "./roblox-world/objects/zone-c-tokyo-central-station-design.md"
  - "./roblox-world/objects/zone-c-ShinbashiGuardUnderpass-design.md"
  - "./roblox-world/objects/zone-c-tsukiji-outer-market-area-design.md"
  - "./roblox-world/scripts/client/info-board/ShopBoard_PopUpController.lua"
  - "./roblox-world/scripts/client/info-board/OmoideYokocho_PropController.lua"
  - "./roblox-world/scripts/client/info-board/ShinbashiGuardUnderpass_PropController.lua"
  - "./roblox-world/scripts/client/info-board/Tsukiji_PropController.lua"
  - "./roblox-world/docs/learning/2026-08-16-lua-learning-log.md"
  - "./roblox-world/docs/learning/2026-09-17-blender_learning_log.md"
  - "./roblox-world/docs/learning/2026-09-21-blender_learning_log.md"
  - "./roblox-world/docs/learning/2026-09-22-blender_learning_log.md"
  - "./roblox-world/docs/learning/2026-09-26-blender_learning_log.md"
  - "./roblox-world/docs/learning/2026-09-29-blender_learning_log.md"
  - "./roblox-world/docs/learning/2026-09-30-blender_learning_log.md"
  - "./roblox-world/docs/learning/2026-10-19-blender_learning_log.md"
  - "./roblox-world/docs/learning/2026-10-20-blender_learning_log.md"
  - "./roblox-world/docs/learning/2026-10-30-blender_learning_log.md"
description: "Virtual Tokyo Trip Planner プロジェクトのドキュメント構造、相対パス、および各ファイルの役割をまとめたメインインデックス"
---

# Virtual Tokyo Trip Planner - Project Index

本プロジェクトのドキュメント構造、依存関係（相対パス）、および各ファイルの役割をまとめたメインインデックスです。

---

## 📂 ディレクトリ構造とファイル一覧

    virtual-tokyo-trip-planner/
    ├─ README.md
    ├─ index.md (本ファイル)
    ├─ planning/
    │  ├─ presentation-schedule.md
    │  ├─ milestone-1-progress.md
    │  └─ tokyo-trip-plan-2026.md
    └─ roblox-world/
       ├─ assets/
       │  ├─ accommodations-boards-design.svg
       │  ├─ omoideyokocho-outer-market-elevation-spec.svg
       │  ├─ omoideyokocho-outer-market-plan-spec.svg
       │  ├─ room-layout-diagram.svg
       │  ├─ specific-spot-shop-boards-design.svg
       │  ├─ tokyo-central-station-elevation-spec.svg
       │  ├─ tokyo-central-station-plan-spec.svg
       │  ├─ tsukiji-outer-market-elevation-spec.svg
       │  └─ tsukiji-outer-market-plan-spec.svg
       ├─ docs/
       │  └─ learning/
       │     ├─ 2026-08-16-lua-learning-log.md
       │     ├─ 2026-09-17-blender_learning_log.md
       │     ├─ 2026-09-21-blender_learning_log.md
       │     ├─ 2026-09-22-blender_learning_log.md
       │     ├─ 2026-09-26-blender_learning_log.md
       │     ├─ 2026-09-29-blender_learning_log.md
       │     ├─ 2026-09-30-blender_learning_log.md
       │     ├─ 2026-10-19-blender_learning_log.md
       │     ├─ 2026-10-20-blender_learning_log.md
       │     └─ 2026-10-30-blender_learning_log.md
       ├─ objects/
       │  ├─ info-board-accommodation.md
       │  ├─ info-board-featured-spots.md
       │  ├─ info-board-specific-shops.md
       │  ├─ room-spatial-dimension-spec.md
       │  ├─ room-wall-design-spec.md
       │  ├─ workspace-hierarchy.md
       │  ├─ zone-c-omoideyokocho-design.md
       │  ├─ zone-c-ShinbashiGuardUnderpass-design.md
       │  ├─ zone-c-tokyo-central-station-design.md
       │  └─ zone-c-tsukiji-outer-market-area-design.md
       ├─ scripts/
       │  └─ client/
       │     └─ info-board/
       │        ├─ OmoideYokocho_PropController.lua
       │        ├─ ShinbashiGuardUnderpass_PropController.lua
       │        ├─ ShopBoard_PopUpController.lua
       │        └─ Tsukiji_PropController.lua
       ├─ object-deployment-plan.md
       ├─ room-floor-design-spec.md
       └─ room-layout-design.md

---

## 📜 ドキュメント詳細とナビゲーション

### 1. プロジェクトルート

* **README.md** (`./README.md`)
  * **役割**: プロジェクトの概要、目的、リポジトリの基本情報を記述するメイン説明書。
* **index.md** (`./index.md`)
  * **役割**: 全ファイルの構造と主要ドキュメントへのナビゲーションを管理するインデックス。

### 2. 旅行計画 (`planning/`)

* **presentation-schedule.md** (`./planning/presentation-schedule.md`)
  * **役割**: Robloxプロジェクトの3つのプレゼンテーション・マイルストーンと、各段階の開発目標・アクション項目を管理するスケジュール。
* **milestone-1-progress.md** (`./planning/milestone-1-progress.md`)
  * **役割**: 第一回プレゼンテーションに向けた案内板、ワールド環境、3Dオブジェクト等の進捗管理票。
* **tokyo-trip-plan-2026.md** (`./planning/tokyo-trip-plan-2026.md`)
  * **役割**: 2026年の東京旅行（第1回・第2回）の日程、宿泊先、飲食店、観光スポットをまとめた基本計画。

### 3. Roblox ワールド設計 (`roblox-world/`)

#### アセット (`assets/`)

* **assets/** (`./roblox-world/assets/`)
  * **役割**: ワールド、案内板、各エリアの設計図などのSVGアセットを格納します。
  * **アセット一覧**:
    * `accommodations-boards-design.svg` — 宿泊施設案内板のデザイン。
    * `omoideyokocho-outer-market-elevation-spec.svg` / `omoideyokocho-outer-market-plan-spec.svg` — 思い出横丁エリアの立面図・平面図。
    * `room-layout-diagram.svg` — ルーム全体のレイアウト図。
    * `specific-spot-shop-boards-design.svg` — 店舗・施設案内板のデザイン。
    * `tokyo-central-station-elevation-spec.svg` / `tokyo-central-station-plan-spec.svg` — 東京中央駅エリアの立面図・平面図。
    * `tsukiji-outer-market-elevation-spec.svg` / `tsukiji-outer-market-plan-spec.svg` — 築地場外市場エリアの立面図・平面図。

#### 計画・空間仕様

* **object-deployment-plan.md** (`./roblox-world/object-deployment-plan.md`)
  * **役割**: 旅行計画をRoblox空間上の床材、案内板、ランドマーク、3Dモデル、プロップへ対応付ける配置計画。
  * **主要関連リンク**: `../planning/tokyo-trip-plan-2026.md`、`./room-layout-design.md`、`./room-floor-design-spec.md`、`./objects/` 配下の案内板・ゾーン仕様書。
* **room-layout-design.md** (`./roblox-world/room-layout-design.md`)
  * **役割**: 円形ルーム構造、スポーン地点、放射状ゾーン配置など、Robloxワールド全体の空間デザインを定義します。
* **room-floor-design-spec.md** (`./roblox-world/room-floor-design-spec.md`)
  * **役割**: 3つの階層シリンダー床パーツの構造、寸法、材質、色を定義する仕様書。
* **objects/room-spatial-dimension-spec.md** (`./roblox-world/objects/room-spatial-dimension-spec.md`)
  * **役割**: Zone A/B/C の寸法や外壁・案内板の配置座標など、ワールドの空間計算をまとめた仕様書。
* **objects/room-wall-design-spec.md** (`./roblox-world/objects/room-wall-design-spec.md`)
  * **役割**: メインウォール・サブウォールの寸法、配置、トランスフォーム、材質・色を定義する仕様書。
* **objects/workspace-hierarchy.md** (`./roblox-world/objects/workspace-hierarchy.md`)
  * **役割**: Roblox Workspace内のオブジェクト階層、命名規約、パーツの親子関係を定義するリファレンス。

#### 案内板仕様 (`objects/`)

* **info-board-featured-spots.md** (`./roblox-world/objects/info-board-featured-spots.md`)
  * **役割**: 主要観光スポット案内板の3Dパーツ構造、材質・カラー、およびSurfaceGuiレイアウトを定義します。
* **info-board-specific-shops.md** (`./roblox-world/objects/info-board-specific-shops.md`)
  * **役割**: 飲食店・ショップ等の案内板の3Dパーツ構造、材質・カラー、SurfaceGuiレイアウトを定義します。店舗ボードのポップアップ制御スクリプトとも連携します。
* **info-board-accommodation.md** (`./roblox-world/objects/info-board-accommodation.md`)
  * **役割**: 宿泊施設案内板の3Dパーツ構造、色・材質、ホテル情報や施設アイコンを含むSurfaceGuiレイアウトを定義します。

#### Zone C エリア設計 (`objects/`)

* **zone-c-omoideyokocho-design.md** (`./roblox-world/objects/zone-c-omoideyokocho-design.md`)
  * **役割**: InfoBoard_02 思い出横丁前の空間、赤提灯プロップの配置、接近時の出現・点灯演出を定義します。
* **zone-c-tokyo-central-station-design.md** (`./roblox-world/objects/zone-c-tokyo-central-station-design.md`)
  * **役割**: InfoBoard_10 東京中央駅前の空間と青色ランタンプロップ群の配置・グループ出現演出を定義します。
* **zone-c-ShinbashiGuardUnderpass-design.md** (`./roblox-world/objects/zone-c-ShinbashiGuardUnderpass-design.md`)
  * **役割**: InfoBoard_12 新橋ガード下前の空間、赤提灯プロップの配置、接近時の出現・点灯演出を定義します。
* **zone-c-tsukiji-outer-market-area-design.md** (`./roblox-world/objects/zone-c-tsukiji-outer-market-area-design.md`)
  * **役割**: InfoBoard_13 築地場外市場前の空間、寿司プロップの配置、歩行動線に沿った出現演出を定義します。

#### スクリプト (`scripts/`)

* **scripts/** (`./roblox-world/scripts/`)
  * **役割**: Robloxクライアント側のLuaスクリプトを格納します。
  * **client/info-board/ShopBoard_PopUpController.lua** — 店舗案内板に接近した際のポップアップ表示を制御するLocalScript。
  * **client/info-board/OmoideYokocho_PropController.lua** — 思い出横丁の赤提灯の出現・点灯・サウンド演出を制御するLocalScript。
  * **client/info-board/ShinbashiGuardUnderpass_PropController.lua** — 新橋ガード下の赤提灯の出現・点灯・サウンド演出を制御するLocalScript。
  * **client/info-board/Tsukiji_PropController.lua** — 築地の寿司プロップの順次出現アニメーションを制御するLocalScript。

#### 学習ログ (`docs/learning/`)

* **docs/learning/** (`./roblox-world/docs/learning/`)
  * **役割**: Roblox開発に関する学習ログ、技術ノート、知見を格納します。
  * `2026-08-16-lua-learning-log.md` — Luaの基本構文、テーブル・ループ、Roblox API等の学習ログ。
  * `2026-09-17-blender_learning_log.md`、`2026-09-21-blender_learning_log.md`、`2026-09-22-blender_learning_log.md`、`2026-09-26-blender_learning_log.md`、`2026-09-29-blender_learning_log.md`、`2026-09-30-blender_learning_log.md`、`2026-10-19-blender_learning_log.md`、`2026-10-20-blender_learning_log.md`、`2026-10-30-blender_learning_log.md` — Blenderでの制作・モデリング学習ログ（日付順）。

---

## 🔗 相対パス参照ルール（クイックリファレンス）

ドキュメント間で相互リンクや画像参照を行う際は、自身のファイル位置を基準に以下のルールでパスを記述します。

* **同じフォルダ内のファイルを参照する場合**: `./filename.md`
* **1つ上のフォルダに戻って参照する場合**: `../filename.md` または `../folder/filename.md`
* **ルート(`index.md`)から配下を参照する場合**: `./planning/...` や `./roblox-world/...`

