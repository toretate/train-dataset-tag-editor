/**
 * タグの共通設定ファイルの I/O など
 */

import { useMainStore } from '../../stores/mainStore'

/**
 * 共通タグなどの設定値をロードする
 * フォルダの tag-settings.json から読み込む
 */
export const useLoadTagSettings = async (file: File) => {
    const store = useMainStore()
    try {
        const text = await file.text();
        const settings = JSON.parse(text);
        if (settings.commonTagPre) store.setCommonTagPre(settings.commonTagPre);
        if (settings.commonTagPost) store.setCommonTagPost(settings.commonTagPost);
        if (settings.commonAddTag) store.setCommonAddTag(settings.commonAddTag);
        if (settings.commonDelTag) store.setCommonDelTag(settings.commonDelTag);
    } catch (error) {
        console.error('Error reading tag-settings.json:', error)
    };
}

/**
 * 設定の保存
 * @param handle 保存先のファイルハンドル (未指定の場合はダイアログを表示して選択)
 */
export const useSaveTagSettings = async ( handle?: FileSystemFileHandle ) => {
    const store = useMainStore()

    // Fiele System Access API で保存
    if (!store.targetDirHandle) {
        console.error('No target directory handle available for saving settings.');
        return;
    }

    // 保存されるデータ
    const settings = {
        commonTagPre: store.commonTagPre,   
        commonTagPost: store.commonTagPost,
        commonAddTag: store.commonAddTag,
        commonDelTag: store.commonDelTag,
    };
    const json = JSON.stringify(settings, null, 2);
    const blob = new Blob([json], { type: 'application/json' });

    // File System Access API で保存
    if( !handle ) {
        handle = await window.showSaveFilePicker({
            suggestedName: 'tag-settings.json',
        });
    }
    const writableStream = await handle.createWritable()
    await writableStream.write(blob);
    await writableStream.close();
}

