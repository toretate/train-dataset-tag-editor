<template>
    <div>
        <!-- 画像サイズ選択UI -->
        <v-toolbar density="compact">
            <template v-slot:append>
                <v-btn icon="mdi-content-save-all" size="small"></v-btn>
                <v-btn-toggle density="compact" divided v-model="thumbnailSize" mandatory>
                    <v-btn size="x-small" value="x-small"><v-icon size="x-small">mdi-image</v-icon></v-btn>
                    <v-btn size="x-small" value="medium"><v-icon size="medium">mdi-image</v-icon></v-btn>
                    <v-btn size="x-small" value="x-large"><v-icon size="x-large">mdi-image</v-icon></v-btn>
                </v-btn-toggle>
            </template>
        </v-toolbar>
    </div>

    <!-- ファイル選択リスト -->
    <v-table class="file-list">
        <thead>
            <tr>
                <th></th>
                <th>タグ(共通タグ,削除を除く)</th>
                <th>入っていない共通タグ</th>
                <th>削除タグ</th>
                <th></th>
            </tr>
        </thead>
        <tbody>
            <template v-for="(item, index) in directoryContents" :key="index">
                <tr v-if="item.type === 'file' && item.file && item.name.match(IMAGE_FILE_EXTENSIONS)">
                    <image-and-directory-table-row
                        :item="item"
                        :thumbnailSize="thumbnailSize"
                        @file-selected="emitSelectedFile"
                        :show-tag="showTag"
                        :show-name="showName"
                    />
                </tr>
            </template>
        </tbody>
    </v-table>
</template>

<script setup lang="ts">
import { ref, watch, onMounted, defineEmits } from 'vue';
import ImageAndDirectoryTableRow from './ImageAndDirectoryTableRow.vue';

// 対応画像拡張子
const IMAGE_FILE_EXTENSIONS = /\.(png|jpe?g|gif|bmp|webp)$/i;

// プロパティ
const props = defineProps<{
    directory: FileSystemDirectoryHandle | null;
    showTag?: boolean;
    showName?: boolean;
}>();
const showTag = props.showTag ?? false;
const showName = props.showName ?? true;

// data
const thumbnailSize = ref<'x-small' | 'small' | 'medium' | 'large' | 'x-large'>('x-small');
const directoryContents = ref<DirectoryItem[]>([]);

// 外部へのイベント通知
const emits = defineEmits<{
    (e: 'file-selected', value: File): void
}>();

const fetchDirectoryContents = async () => {
    if (props.directory) {
        directoryContents.value = [];

        const contents = [];
        for await (const entry of props.directory.values()) {
            const item: DirectoryItem = {
                name: entry.name,
                type: entry.kind as 'file' | 'directory',
            };

            // ファイルの場合は File オブジェクトを取得
            if (entry.kind === 'file') {
                const fileHandle = entry as FileSystemFileHandle;
                item.file = await fileHandle.getFile();
            }

            contents.push(item);
        }

        // ディレクトリを優先してソート
        contents.sort((a, b) => {
            if (a.type === 'directory' && b.type !== 'directory') return -1;
            if (a.type !== 'directory' && b.type === 'directory') return 1;
            return a.name.localeCompare(b.name);
        });
        directoryContents.value = contents;
    }
};

const emitSelectedFile = (file: File) => {
    emits( 'file-selected', file );
};

watch(
    () => props.directory,
    () => {
        fetchDirectoryContents();
    },
    { immediate: true }
);

onMounted(() => {
    fetchDirectoryContents();
});
</script>

<style lang="scss" scoped>
.filelist-wrapper {
    height: 100%;

    .file-list {
        height: 100%;
        overflow-y: auto;
        list-style: none;
        padding: 0;
    }
}

.directory-name {
    font-size: 1.5em;
    margin-bottom: 0.5em;
}



</style>