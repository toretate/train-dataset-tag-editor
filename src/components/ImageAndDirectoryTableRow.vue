<!-- 
    ImageAndTagListItem.vue
    画像ファイルとディレクトリをリスト表示するコンポーネント
-->
<template>
    <td>
        <v-lazy transition="fade-transition" :key="item.file!.name">
            <v-img
                :src="getImageUrl(item.file!)"
                :class="'thumbnail' + ' ' + thumbnailSize"
            />
        </v-lazy>
    </td>
    <td><!-- 共通タグを除いたもの -->
        <v-textarea
            v-model="tagsFiltered"
            type="text"
            variant="outlined"
            :hide-details="true"
            density="compact"
            rows="3"
            @update:focused="onTagsFilteredFocused"
            />
    </td>
    <td><!-- 共通タグに入っていないもの -->
        <v-textarea
            v-model="tagsNotFound"
            type="text"
            variant="outlined"
            :hide-details="true"
            density="compact"
            readonly disabled 
            rows="3"
            />                
    </td>
    <td><!-- 共通タグから削除するもの -->
        <v-textarea
            v-model="item.removeTags"
            type="text"
            variant="outlined"
            :hide-details="true"
            density="compact"
            rows="3"
            />
    </td>
    <td>
        <!-- 保存ボタン(タグファイルが無いものは plus を付ける) -->
        <v-btn :icon="hasTagFile ? 'mdi-content-save' : 'mdi-content-save-plus'">
        </v-btn>
    </td>
</template>
<script setup lang="ts">
import { defineComponent, ref, watch, onMounted, defineEmits, computed } from 'vue';
import { useMainStore } from "../stores/mainStore";

/** 拡張子を除いたファイル名部分を返す */
const getFileNameWithoutExtension = (file: File): string => {
    const fileName = file.name;
    const lastDotIndex = fileName.lastIndexOf('.');
    return lastDotIndex !== -1 ? fileName.substring(0, lastDotIndex) : fileName;
};

const store = useMainStore();

// プロパティ
const props = defineProps<{
    item: DirectoryItem;
    thumbnailSize: 'x-small' | 'small' | 'medium' | 'large' | 'x-large';
}>();
const commonTagPre = computed( () => (store.commonTagPre || "").split(",").map(s => s.trim()) );
const commonTagPost = computed( () => (store.commonTagPost || "").split(",").map(s => s.trim()) );
const removeTags = computed( () => (props.item.removeTags || "").split(",").map(s => s.trim()) );

// 外部へのイベント通知
const emits = defineEmits<{
    (e: 'file-selected', value: File): void
}>();

const hasTagFile = computed( () => {
    if( !props.item.file ) return false;
    const fileName = getFileNameWithoutExtension( props.item.file );
    return ( store.tagText![fileName] || '' ).trim().length > 0;
});

// タグ一覧(カンマ区切り)を配列化したもの
const tags = computed(
    () => {
        if( !props.item.file ) return [];
        const fileName = getFileNameWithoutExtension( props.item.file );
        return ( store.tagText![fileName] || '' ).split(",").map(v => v.trim());
    },
);

// タグ(共通タグ、削除を除く) 
const tagsFiltered = ref("");
const updateTagsFiltered = () => {
    // 共通タグを削除し、「削除タグ」も削除
    let tmp = tags.value
        .filter( t => (commonTagPre.value).includes(t) === false )
        .filter( t => (commonTagPost.value).includes(t) === false )

        ;
    tagsFiltered.value = tmp.join(", ");
};
updateTagsFiltered() // 初期化
watch( [tags, commonTagPre, commonTagPost], updateTagsFiltered); // tags, 共通タグ が変わったら更新

// 共通タグで未登録のもの
const tagsNotFound = computed(
    () => {
        const tmp = tags.value;
        const common = [...commonTagPre.value, ...commonTagPost.value];
        let remain = common.filter( c => tmp.includes(c) === false );
        remain = remain.filter( t => (removeTags.value).includes(t) === false );
        return remain.join(", ");
    },
);

// メソッド
const getImageUrl = (file: File) => {
    return URL.createObjectURL(file);
};

// イベントハンドラ

const onTagsFilteredFocused = ( focused: boolean ) => {
    if( focused ) return;   // フォーカス時には何もしない
    if( !props.item.file ) return;

    const fileName = getFileNameWithoutExtension( props.item.file );
    if ( fileName.length === 0 ) return;

    // フォーカスを外れたら、タグ更新を行う
    // [共通タグ(pre), ... , filteredタグ, ... , 共通タグ(post)] の順に並べる
    // そのあと、removeTags に含まれるものを削除する
    const updatedTags = [
        ...commonTagPre.value,
        ...tagsFiltered.value.split(",").map(s => s.trim()),
        ...commonTagPost.value
    ]   .filter(tag => !removeTags.value.includes(tag))
        .join(", ")
        ;
    store.setTagText(fileName, updatedTags);
};

</script>

<style lang="scss" scoped>
    td {
        padding-left: 0px !important;
        padding-right: 0px !important;
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
</style>