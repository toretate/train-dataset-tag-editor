import { set } from '@vueuse/core';
import { defineStore } from 'pinia';

export const useMainStore = defineStore('main', {
    state: () => ({
        targetDir: null as string | null,
        targetDirAbsPath: null as string | null,
        targetDirHandle: null as FileSystemDirectoryHandle | null,
        targetImageFileUrl: undefined as string | undefined,
        targetTagText: null as string | null,
        targetFilterTagText: null as string | null,
        targetAddTagText: null as string | null,
        targetDelTagText: null as string | null,
        directoryContents: [] as DirectoryItem[],
        listMode: 'list' as 'panel' | 'list' | 'single',

        // 画像ごとのタグテキストを保持する連想配列
        tagText: {} as Record<string, string | null>,

        commonTagPre: '' as string, // 共通タグ(pre)
        commonTagPost: '' as string,// 共通タグ(post)
        commonAddTag: '' as string, // 共通追加タグ
        commonDelTag: '' as string, // 共通削除タグ

        // アプリの設定
        thumbnailSize: 'x-small' as 'x-small' | 'small' | 'medium' | 'large' | 'x-large',
    }),
    actions: {
        setTargetDir(dir: string | null) {
            this.targetDir = dir;
        },
        setTargetDirAbsPath(path: string | null) {
            this.targetDirAbsPath = path;
        },
        setTargetDirHandle(handle: FileSystemDirectoryHandle | null) {
            this.targetDirHandle = handle;
        },
        setDirectoryContents(contents: DirectoryItem[]) {
            this.directoryContents = contents;
        },
        setTargetImageFileUrl(url: string | undefined) {
            this.targetImageFileUrl = url;
        },
        setTargetTagText(text: string | null) {
            this.targetTagText = text;
        },

        // 画像ごとのタグテキストを設定
        setTagText( key: string, text: string | null ) {
            this.tagText[key] = text;
        },

        // タグテキストをクリア。ディレクトリ変更時に使用してください
        clearTagText() { this.tagText = {}; },


        // タグ設定
        setCommonTagPre(tag: string) { this.commonTagPre = tag; },
        setCommonTagPost(tag: string) { this.commonTagPost = tag; },
        setCommonAddTag(tag: string) { this.commonAddTag = tag; },
        setCommonDelTag(tag: string) { this.commonDelTag = tag; },

        // Clear処理
        clear() {
            this.tagText = {};

            this.commonTagPre = '';
            this.commonTagPost = '';
            this.commonAddTag = '';
            this.commonDelTag = '';
        }
    },
});