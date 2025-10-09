<!-- ディレクトリ選択ツールボタン -->
<template>
    <!-- <v-app-bar-nav-icon></v-app-bar-nav-icon> -->
    <v-btn icon="mdi-directory" @click="onFileMenuClick">
        <v-icon>mdi-folder</v-icon>
    </v-btn>
    <v-app-bar-title>{{ targetDirAbsPath ?? '(ディレクトリ未選択)' }}</v-app-bar-title>
</template>

<script lang="ts" setup>
import { ref, computed } from 'vue';
import { useMainStore } from '../stores/mainStore'
import { useLoadTagSettings } from './function/tag-settings';

const store = useMainStore()

// targetDir を Pinia ストアから取得
const targetDirHandle = computed(() => store.targetDirHandle);
const targetDirAbsPath = computed(() => store.targetDirAbsPath);

/**
 * 共通タグなどの設定値をロードする
 * フォルダの tag-settings.json から読み込む
 */
const loadTagSettings = async (file: File) => {
    return await useLoadTagSettings( file )
}

// 画像ファイルに対応するタグ情報をロードする
const loadTagText = async (file: File) => {
    if( !targetDirHandle.value ) return;

    // 拡張子を除いたファイル名を取得
    const fileName = file.name.replace(/\.[^/.]+$/, '');
    const tagText = await file.text();

    try {
        store.setTagText( fileName, tagText )
    } catch (error) {
        console.error('Error reading the txt file:', error)
    }
}


/**
 * ディレクトリ内のファイル一覧を取得
 * * 画像ファイル(.png, .jpg, .jpeg, .bmp, .gif, .webp)
 * * タグファイル(.txt)
 * * タグ設定ファイル(tag-settings.json)
 */
const fetchDirectoryContents = async ( directory: FileSystemDirectoryHandle ) => {
    store.clear()
    store.setDirectoryContents( [] )

    const contents = [];
    for await (const entry of directory.values()) {
        const item: DirectoryItem = {
            name: entry.name,
            type: entry.kind as 'file' | 'directory',
        };

        // ファイルの場合は File オブジェクトを取得
        if (entry.kind === 'file') {
            const fileHandle = entry as FileSystemFileHandle;
            item.file = await fileHandle.getFile();

            if(entry.name.match( /\.(txt)$/i )){
                // タグファイルの場合はロード
                await loadTagText( item.file )
            } else if(entry.name === 'tag-settings.json'){
                // タグ設定ファイルの場合はロード
                await loadTagSettings( item.file );
                store.setCommonTagSettingFile( entry );
            }
        }

        contents.push(item);
    }

    // ディレクトリを優先してソート
    contents.sort((a, b) => {
        if (a.type === 'directory' && b.type !== 'directory') return -1;
        if (a.type !== 'directory' && b.type === 'directory') return 1;
        return a.name.localeCompare(b.name);
    });
    store.setDirectoryContents( contents );
};

// ディレクトリの絶対パスを取得
const getFileAbsolutePath = async (directoryHandle: FileSystemDirectoryHandle): Promise<string> => {
    const paths: string[] = [];
    let currentHandle: FileSystemDirectoryHandle | null = directoryHandle;

    while (currentHandle) {
        paths.unshift(currentHandle.name);
        try {
            currentHandle = await currentHandle.getParent();
        } catch {
            break; // If getParent is not supported or fails, exit the loop
        }
    }

    return '/' + paths.join('/');
};


// ディレクトリ選択
async function onFileMenuClick() {
    try {
        // File System Access API を使用してディレクトリ選択ダイアログを表示
        const directoryHandle = await window.showDirectoryPicker()
        // 選択されたディレクトリの名前を targetDir に設定
        store.setTargetDir( directoryHandle.name )
        store.setTargetDirHandle( directoryHandle )
        console.log('Selected directory:', directoryHandle)
        fetchDirectoryContents( directoryHandle ).then(() => {
            console.log('Directory contents fetched')
        })

        getFileAbsolutePath(directoryHandle).then((absPath) => {
            store.setTargetDirAbsPath( absPath )
        })
    } catch (error) {
        console.error('Directory selection was canceled or failed:', error)
    }
}



</script>