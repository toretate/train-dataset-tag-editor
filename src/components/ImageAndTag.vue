<template>
    <Splitpanes
        class="default-theme"
        horizontal
        @resized="onSplitterResized"
        @splitter-dblclick="onSplitterDblClicked"
        :maximize-panes="false"
        >

        <!-- 画像表示パネル -->
        <Pane :size="paneSize1" min-size="10">
            <img :src="targetImageFileUrl" style="object-fit: scale-down; width: 100%;"/>
        </Pane>

        <!-- タグ表示パネル -->
        <Pane :size="100 - paneSize1" min-size="10" >
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
<script setup lang="ts">
import { useMainStore } from '../stores/mainStore'
import { ref, computed } from 'vue'
import { Splitpanes, Pane } from 'splitpanes'
import 'splitpanes/dist/splitpanes.css'

const paneSizeData = JSON.parse( localStorage.panes2 ?? "[30, 70]" ) as number[]
const paneSize1 = ref( paneSizeData[0] )
const paneSize2 = ref( paneSizeData[1] )

type PANE = typeof Pane;
const store = useMainStore()
const targetImageFileUrl = computed(() => store.targetImageFileUrl);
const targetTagText = computed(() => store.targetTagText);

const savePaneSizes = ( panes: number[] ) => {
    localStorage.setItem( 'panes2', JSON.stringify( panes ) )
}

const onSplitterResized = ( { panes }: { panes: PANE[] } ) => {
    const paneSizeList = panes.map( p => p.size )
    savePaneSizes( paneSizeList )
}

const onSplitterDblClicked = ( { index, panes }: { index: number, panes: PANE[], prevPane: PANE, nextPane: PANE } ) => {
  // 初期サイズに戻す
  switch( index ) {
    case 1:
      paneSizeData[0] = 30
      paneSize1.value = paneSizeData[0]
      break
    case 2:
      paneSizeData[1] = 70
      paneSize2.value = paneSizeData[2]
      break
    default:
      break
  }
  savePaneSizes( paneSizeData )
}

</script>