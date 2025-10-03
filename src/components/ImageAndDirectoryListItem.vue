<!-- 
    ImageAndTagListItem.vue
    画像ファイルとディレクトリをリスト表示するコンポーネント
-->
<template>
    <v-list-item v-if="item.type === 'file' && item.file && item.name.match(/\.(png|jpe?g|gif|bmp|webp)$/i)"
        class="file-item"
        v-on:click="handleItemClick(item)"
        >
        <div class="file-item-row">
        <v-lazy transition="fade-transition" :key="item.file.name">
            <div class="file-item-content">
                <v-img
                    :src="getImageUrl(item.file)"
                    :class="'thumbnail' + ' ' + thumbnailSize"
                />
                <span> {{ getFileNameWithoutExtension(item.file!) }}</span>
            </div>
        </v-lazy>
        <v-textarea
            v-if="showTag"
            v-model="tags"
            type="text"
            variant="outlined"
            :hide-details="true"
            density="compact"
            clearable
            rows="3"
            />
        </div>
    </v-list-item>
    <v-list-item v-else-if="item.type === 'directory'">
        <span>📁 {{ getFileNameWithoutExtension( item.file! ) }}</span>
    </v-list-item>
</template>
<script setup lang="ts">
import { defineComponent, ref, watch, onMounted, defineEmits, computed } from 'vue';
import { useMainStore } from "../stores/mainStore";

const store = useMainStore();

interface DirectoryItem {
    name: string;
    type: 'file' | 'directory';
    file?: File; // ファイルの場合に File オブジェクトを保持
}

// プロパティ
const props = defineProps<{
    item: DirectoryItem;
    thumbnailSize: 'x-small' | 'small' | 'medium' | 'large' | 'x-large';
    showTag?: boolean;
}>();

// 外部へのイベント通知
const emits = defineEmits<{
    (e: 'file-selected', value: File): void
}>();

const tags = computed(
    () => {
        if( !props.item.file ) return '';
        const fileName = getFileNameWithoutExtension( props.item.file );
        let tmp = ( store.tagText![fileName] || '' ).trim().split(",");
        // 共通タグを削除
        tmp = tmp.filter( t => (store.commonTagPre || "").split(",").map(s => s.trim()).includes(t.trim()) === false );
        tmp = tmp.filter( t => (store.commonTagPost || "").split(",").map(s => s.trim()).includes(t.trim()) === false );
        return tmp.join(", ");
    },
);

// メソッド
const getImageUrl = (file: File) => {
    return URL.createObjectURL(file);
};

/** 拡張子を除いたファイル名部分を返す */
const getFileNameWithoutExtension = (file: File): string => {
    const fileName = file.name;
    const lastDotIndex = fileName.lastIndexOf('.');
    return lastDotIndex !== -1 ? fileName.substring(0, lastDotIndex) : fileName;
};


// イベントハンドラ
const handleItemClick = (item: DirectoryItem) => {
    if (item.type === 'file' && item.file) {
        emits( 'file-selected', item.file );
    }
};


</script>

<style lang="scss" scoped>
.file-item {
    margin: 4px 0;
    font-size: 1em;
    &:hover {
        background-color: #f8f8f8;
        cursor: pointer;
    }

    .file-item-row {
        display: flex;
        align-items: center;
        gap: 16px;
    }

    .file-item-content {
        overflow:hidden;
        white-space: nowrap;                
    }

    .thumbnail {
        margin-left: 4px;
        margin-right: 4px;
        display: inline-block;
        vertical-align: middle;
        object-fit: scale-down;

        &.x-small {
            width: 50px;
            height: 50px;
        }
        &.small {
            width: 75px;
            height: 75px;
        }
        &.medium {
            width: 100px;
            height: 100px;
        }
        &.large {
            width: 125px;
            height: 125px;
        }
        &.x-large {
            width: 150px;
            height: 150px;
        }
    }            
}
</style>