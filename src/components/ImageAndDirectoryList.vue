<template>
    <div>
        <h2>{{ directory?.name || 'No Directory Selected' }}</h2>
        <ul>
            <template v-for="(item, index) in directoryContents" :key="index">
                <li v-if="item.type === 'file' && item.file && item.name.match(/\.(png|jpe?g|gif|bmp|webp)$/i)"
                    class="file-item"
                    v-on:click="handleItemClick(item)"
                    >
                    <img
                        v-lazy="getImageUrl(item.file)"
                        :key="item.file.name"
                        loading="lazy"
                        alt="Image"
                        class="thumbnail"
                    />
                    <span> {{ getFileNameWithoutExtension(item) }}</span>
                </li>
                <li v-else-if="item.type === 'directory'">
                    <span>📁 {{ getFileNameWithoutExtension( item ) }}</span>
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
h2 {
    font-size: 1.5em;
    margin-bottom: 0.5em;
}
ul {
    list-style: none;
    padding: 0;
}
li {
    margin: 0.5em 0;
    font-size: 1.2em;
}

.file-item {
    &:hover {
        background-color: #f8f8f;
        cursor: pointer;
    }
}

.thumbnail {
    border-radius: 8px;
    width: 100px;
    height: 100px;
    margin-right: 0.5em;
    display: inline-block;
    vertical-align: middle;
    object-fit: scale-down;
}
</style>