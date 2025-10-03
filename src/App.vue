<script setup lang="ts">
import { useMainStore } from './stores/mainStore'
import { ref, computed } from 'vue'
import ImageAndDirectoryList from './components/ImageAndDirectoryList.vue'
import { Splitpanes, Pane } from 'splitpanes'
import 'splitpanes/dist/splitpanes.css'
import DirectorySelectionToolButton from './components/DirectorySelectionToolButton.vue'

const store = useMainStore()
type PANE = typeof Pane;

// targetDir を Pinia ストアから取得
const targetDirHandle = computed(() => store.targetDirHandle);
const targetImageFileUrl = computed(() => store.targetImageFileUrl);
const targetTagText = computed(() => store.targetTagText);

// 画像一覧の表示モード
const listMode = ref<'panel' | 'list' | 'single' >('list')

// SplitPanes のサイズ変更のPersistence処理
const paneSizeData = JSON.parse( localStorage.panes ?? "[30, 40, 30]" ) as number[]
console.log( paneSizeData )
const paneSize1 = ref( paneSizeData[0] )
const paneSize3 = ref( paneSizeData[2] )
const savePaneSizes = ( panes: number[] ) => {
  console.log( panes )
  localStorage.setItem( 'panes', JSON.stringify( panes ) )
}
const onSplitterResized = ( { panes }: { panes: PANE[] } ) => {
  console.log( "Resized", panes.map( p => p.size ) )
  const paneSizeList = panes.map( p => p.size )
  savePaneSizes( paneSizeList )
}
const onSplitterDblClicked = ( { index, panes }: { index: number, panes: PANE[], prevPane: PANE, nextPane: PANE } ) => {
  console.log( "DblClicked", index, panes.map( p => p.size ) )
  // 初期サイズに戻す
  switch( index ) {
    case 1:
      paneSizeData[0] = 30
      paneSize1.value = paneSizeData[0]
      break
    case 2:
      paneSizeData[2] = 30
      paneSize3.value = paneSizeData[2]
      break
    default:
      break
  }
  savePaneSizes( paneSizeData )
}
</script>

<template>
  <v-app>
    <!-- ツールバー -->
    <v-app-bar :elevation="2">
      <DirectorySelectionToolButton />
    </v-app-bar>

    <!-- メイン領域 -->
    <v-main class="main-content">
      <Splitpanes
        class="default-theme"
        @resized="onSplitterResized"
        @splitter-dblclick="onSplitterDblClicked"
        :maximize-panes="false"
        >
        <!-- ディレクトリ選択パネル -->
        <Pane min-size="10" :size="paneSize1">
          <ImageAndDirectoryList :directory="targetDirHandle" />
        </Pane>

        <!-- メイン表示 -->
        <Pane size="100">

          <!-- タグの共通編集コントロール -->
          <v-col>
              <v-text-field label="共通タグ(pre)" type="text" variant="outlined" v-model="store.commonTagPre" density="compact" clearable hide-details />
              <v-text-field label="共通タグ(post)" type="text" variant="outlined" v-model="store.commonTagPost" density="compact" clearable hide-details />
              <v-text-field label="追加" type="text" variant="outlined" v-model="store.commonAddTag" density="compact" clearable  hide-details />
              <v-text-field label="削除" type="text" variant="outlined" v-model="store.commonDelTag" density="compact" clearable  hide-details />
          </v-col>
          <template v-if="listMode === 'panel'">
            <!--  パネル表示用実装 -->
          </template>
          <template v-else-if="listMode === 'list'">
            <ImageAndDirectoryList :directory="targetDirHandle" :show-tag="true" />
          </template>
          <template v-else> <!-- 画像とタグモード -->
            <Splitpanes
              class="default-theme"
              vertical
              @resized="onSplitterResized"
              @splitter-dblclick="onSplitterDblClicked"
              :maximize-panes="false"
              >

              <!-- 画像表示パネル -->
              <Pane :size="100 - paneSize3">
                <img :src="targetImageFileUrl" style="object-fit: scale-down; width: 100%;"/>
              </Pane>

              <!-- タグ表示パネル -->
              <Pane min-size="10" :size="paneSize3">
                <form>
                  <textarea 
                    rows="10" 
                    cols="30" 
                    placeholder="Enter tag text here..." 
                    style="width: 100%; height: 100%;" 
                    v-model="targetTagText">
                  </textarea>
                </form>
              </Pane>
            </Splitpanes>
          </template>
        </Pane>
      </Splitpanes>
    </v-main>
  </v-app>
</template>

<style lang="scss" scoped>
$menu-height: 3rem;

.main-content {
  display: flex;
  flex-direction: row;
  width: 100vw;
  height: calc(100vh - $menu-height); /* Adjusted for fixed menu bar */
  overflow: hidden;
}

header {
  line-height: 1.5;
  max-height: 100vh;
  position: relative;
}

.top-menu-bar {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  background-color: #fff;
  border-bottom: 1px solid var(--color-border);
  z-index: 1000;
  padding: 0.5rem 1rem;

  ul {
    display: flex;
    list-style: none;
    margin: 0;
    padding: 0;
  }

  li {
    margin-right: 1rem;
  }

  a, button {
    text-decoration: none;
    color: var(--color-text);
    font-size: 1rem;

    &:hover {
      text-decoration: underline;
    }
  }
}


.wrapper {
  margin-top: 2rem;
}

.selected-dir {
  margin: 1rem;
  font-size: 1rem;
  color: var(--color-text);
}
</style>
