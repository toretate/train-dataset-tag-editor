interface FileSystemDirectoryHandle {
    /**
     * Returns the parent directory handle if supported by the browser.
     * This method is not part of the standard File System Access API.
     */
    getParent(): Promise<FileSystemDirectoryHandle | null>;

    values(): AsyncIterable<FileSystemHandle>;
}

interface Window {
    showDirectoryPicker: () => Promise<FileSystemDirectoryHandle>;
    showSaveFilePicker: (options?: SaveFilePickerOptions) => Promise<FileSystemFileHandle>;
}

declare module 'splitpanes' {
    import { DefineComponent } from 'vue';
  
    export const Splitpanes: DefineComponent<{}, {}, any>;
    export const Pane: DefineComponent<{}, {}, any>;
}

interface DirectoryItem {
    name: string;
    type: 'file' | 'directory';
    file?: File; // ファイルの場合に File オブジェクトを保持
    removeTags?: string; // 削除タグ
}
