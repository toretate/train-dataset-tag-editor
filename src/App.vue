<script setup lang="ts">
import { ref } from 'vue'
import { computedAsync } from '@vueuse/core'
import { RouterLink, RouterView } from 'vue-router'
import HelloWorld from './components/HelloWorld.vue'
import ImageAndDirectoryList from './components/ImageAndDirectoryList.vue'
import { Splitpanes, Pane } from 'splitpanes'
import 'splitpanes/dist/splitpanes.css'

// targetDir プロパティを定義
const targetDir = ref<string | null>(null)
const targetDirAbsPath = ref<string | null>(null)
const targetDirHandle = ref<FileSystemDirectoryHandle | null>(null)

const targetImageFileUrl = ref<string | null>(null)
const targetTagText = ref<string | null>(null)

const fileSelected = async (file: File) => {
  // 選択されたファイルの処理をここに記述
  console.log('Selected file:', file)
  targetImageFileUrl.value = URL.createObjectURL(file)

  // fileと同名で、拡張子がtxtのファイルの内容をロードして targetTagText に設定
  const txtFileName = file.name.replace(/\.[^/.]+$/, '.txt')
  if (targetDirHandle.value) {
    try {
      for await (const entry of targetDirHandle.value.values()) {
        if (entry.kind === 'file' && entry.name === txtFileName) {
          const fileHandle = await targetDirHandle.value.getFileHandle(entry.name)
          const txtFile = await fileHandle.getFile()
          targetTagText.value = await txtFile.text()
          break
        }
      }
    } catch (error) {
      console.error('Error reading the txt file:', error)
    }
  }
}

// onFileMenuClick 関数を定義
async function onFileMenuClick() {
  try {
    // File System Access API を使用してディレクトリ選択ダイアログを表示
    const directoryHandle = await window.showDirectoryPicker()
    // 選択されたディレクトリの名前を targetDir に設定
    targetDir.value = directoryHandle.name
    targetDirHandle.value = directoryHandle
    console.log('Selected directory:', directoryHandle)

    getFileAbsolutePath(directoryHandle).then((absPath) => {
      targetDirAbsPath.value = absPath
    })
  } catch (error) {
    console.error('Directory selection was canceled or failed:', error)
  }
}

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
</script>

<template>
  <v-app>
    <v-main>
      <v-container>
        <v-app-bar :elevation="2">
          <template v-slot:prepend>
            <!-- <v-app-bar-nav-icon></v-app-bar-nav-icon> -->
            <v-btn icon="mdi-directory" @click="onFileMenuClick">
              <v-icon>mdi-folder</v-icon>
            </v-btn>
          </template>
          <v-app-bar-title>{{ targetDirAbsPath ?? "(ディレクトリ未選択)" }}</v-app-bar-title>
        </v-app-bar>

        <div class="main-content">
          <Splitpanes class="default-theme">
            <Pane min-size="20">
              <ImageAndDirectoryList :directory="targetDirHandle" @file-selected="fileSelected" />
            </Pane>
            <Pane>
              <img :src="targetImageFileUrl" style="object-fit: scale-down; width: 100%;"/>
            </Pane>
            <Pane>
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
        </div>
      </v-container>
    </v-main>
  </v-app>
</template>

<style lang="scss" scoped>
$menu-height: 3rem;

.main-content {
  display: flex;
  flex-direction: row;
  margin-top: $menu-height;
  width: 100vw;
  height: calc(100vh - $menu-height); /* Adjusted for fixed menu bar */
  overflow: hidden;
}

header {
  line-height: 1.5;
  max-height: 100vh;
  position: relative;
}

.top-menu-bar {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  background-color: #fff;
  border-bottom: 1px solid var(--color-border);
  z-index: 1000;
  padding: 0.5rem 1rem;

  ul {
    display: flex;
    list-style: none;
    margin: 0;
    padding: 0;
  }

  li {
    margin-right: 1rem;
  }

  a, button {
    text-decoration: none;
    color: var(--color-text);
    font-size: 1rem;

    &:hover {
      text-decoration: underline;
    }
  }
}


.wrapper {
  margin-top: 2rem;
}

.selected-dir {
  margin: 1rem;
  font-size: 1rem;
  color: var(--color-text);
}
</style>
