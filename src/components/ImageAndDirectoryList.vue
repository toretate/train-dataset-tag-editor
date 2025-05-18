<template>
    <div class="filelist-wrapper">
        <div>
            <v-toolbar density="compact" :title="directory?.name || 'No Directory Selected'">
                <template v-slot:append>
                    <v-btn-toggle density="compact" divided v-model="thumbnailSize" mandatory>
                        <v-btn size="x-small" value="x-small"><v-icon size="x-small">mdi-image</v-icon></v-btn>
                        <v-btn size="x-small" value="medium"><v-icon size="medium">mdi-image</v-icon></v-btn>
                        <v-btn size="x-small" value="x-large"><v-icon size="x-large">mdi-image</v-icon></v-btn>
                    </v-btn-toggle>
                </template>
            </v-toolbar>
        </div>
        <ul class="file-list">
            <template v-for="(item, index) in directoryContents" :key="index">
                <li v-if="item.type === 'file' && item.file && item.name.match(/\.(png|jpe?g|gif|bmp|webp)$/i)"
                    class="file-item"
                    v-on:click="handleItemClick(item)"
                    >
                    <v-lazy transition="fade-transition" :key="item.file.name">
                        <div class="file-item-content">
                            <v-img
                                :src="getImageUrl(item.file)"
                                :class="'thumbnail' + ' ' + thumbnailSize"
                            />
                            <span> {{ getFileNameWithoutExtension(item.file!) }}</span>
                        </div>
                    </v-lazy>
                </li>
                <li v-else-if="item.type === 'directory'">
                    <span>📁 {{ getFileNameWithoutExtension( item.file! ) }}</span>
                </li>
            </template>
        </ul>
    </div>
</template>

<script setup lang="ts">
import { defineComponent, ref, watch, onMounted, defineEmits } from 'vue';

interface DirectoryItem {
    name: string;
    type: 'file' | 'directory';
    file?: File; // ファイルの場合に File オブジェクトを保持
}

// プロパティ
const props = defineProps<{
    directory: FileSystemDirectoryHandle | null;
}>();
const thumbnailSize = ref<'x-small' | 'small' | 'medium' | 'large' | 'x-large'>('x-small');

// 外部へのイベント通知
const emits = defineEmits<{
    (e: 'file-selected', value: File): void
}>();

const directoryContents = ref<DirectoryItem[]>([]);

/** 拡張子を除いたファイル名部分を返す */
const getFileNameWithoutExtension = (file: File): string => {
    const fileName = file.name;
    const lastDotIndex = fileName.lastIndexOf('.');
    return lastDotIndex !== -1 ? fileName.substring(0, lastDotIndex) : fileName;
};

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

const getImageUrl = (file: File) => {
    return URL.createObjectURL(file);
};

const emitSelectedFile = (file: File) => {
    emits( 'file-selected', file );
};

const handleItemClick = (item: DirectoryItem) => {
    if (item.type === 'file' && item.file) {
        emitSelectedFile(item.file);
    }
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

        .file-item {
            margin: 4px 0;
            font-size: 1em;
            &:hover {
                background-color: #f8f8f8;
                cursor: pointer;
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
    }
}

.directory-name {
    font-size: 1.5em;
    margin-bottom: 0.5em;
}



</style>