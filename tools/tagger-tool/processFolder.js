const fs = require('fs');
const path = require('path');
const readline = require('readline');

// サポートする画像拡張子
const SUPPORTED_IMAGE_EXTENSIONS = ['.png', '.jpg', '.jpeg', '.webp'];

// フォルダ内の画像ファイルと同名の .txt ファイルが無ければ作成
function ensureTxtFiles(directory) {
    const files = fs.readdirSync(directory);

    files.forEach((file) => {
        const ext = path.extname(file).toLowerCase();
        const baseName = path.basename(file, ext);

        if (SUPPORTED_IMAGE_EXTENSIONS.includes(ext)) {
            const txtFilePath = path.join(directory, `${baseName}.txt`);
            if (!fs.existsSync(txtFilePath)) {
                fs.writeFileSync(txtFilePath, '', 'utf8');
                console.log(`Created: ${txtFilePath}`);
            }
        }
    });
}

// .txt ファイルを読み込み、カンマ区切りの文字列を配列化
function readTxtFiles(directory) {
    const files = fs.readdirSync(directory);
    const records = [];

    files.forEach((file) => {
        if (path.extname(file).toLowerCase() === '.txt') {
            const filePath = path.join(directory, file);
            const content = fs.readFileSync(filePath, 'utf8');
            const blocks = content
                .split(',')
                .map((block) => block.trim())
                .filter((block) => block !== '');
            records.push({ file, blocks });
        }
    });

    return records;
}

// 重複を排除し、先頭優先でブロックを追加
function addBlocks(userBlocks, records) {
    records.forEach((record) => {
        const uniqueBlocks = new Set(userBlocks.concat(record.blocks));
        record.blocks = Array.from(uniqueBlocks);
    });

    return records;
}

// 指定されたブロックを削除
function deleteBlocks(userBlocks, records) {
    records.forEach((record) => {
        record.blocks = record.blocks.filter((block) => !userBlocks.includes(block));
    });

    return records;
}

// 指定されたブロックを置換
function replaceBlocks(targetBlock, replacementBlock, records) {
    records.forEach((record) => {
        record.blocks = record.blocks.map((block) =>
            block === targetBlock ? replacementBlock : block
        );
    });

    return records;
}

// 各 .txt ファイルに対応するレコードを保存
function saveTxtFiles(directory, records) {
    records.forEach((record) => {
        const filePath = path.join(directory, record.file);
        fs.writeFileSync(filePath, record.blocks.join(','), 'utf8');
        console.log(`Updated: ${filePath}`);
    });
}

// フォルダ選択処理
async function selectFolder(baseDirectory) {
    const folders = fs.readdirSync(baseDirectory).filter((file) => {
        const fullPath = path.join(baseDirectory, file);
        return fs.statSync(fullPath).isDirectory();
    });

    if (folders.length === 0) {
        console.log('No folders found.');
        process.exit(1);
    }

    console.log('Select a folder:');
    folders.forEach((folder, index) => {
        console.log(`${index + 1}: ${folder}`);
    });

    const rl = readline.createInterface({
        input: process.stdin,
        output: process.stdout,
    });

    const answer = await new Promise((resolve) => {
        rl.question('Enter the number of the folder: ', (input) => {
            rl.close();
            resolve(input);
        });
    });

    const selectedIndex = parseInt(answer, 10) - 1;
    if (selectedIndex < 0 || selectedIndex >= folders.length) {
        console.log('Invalid selection.');
        process.exit(1);
    }

    return path.join(baseDirectory, folders[selectedIndex]);
}

// メイン処理
async function main() {
    const baseDirectory = process.cwd();
    let targetDirectory = null;
    let operationType = null;

    // コマンドライン引数の処理
    process.argv.forEach((arg, index) => {
        if (arg === '--type' && process.argv[index + 1]) {
            operationType = process.argv[index + 1];
        }
    });

    if (process.argv.length > 2 && !process.argv.includes('--type')) {
        targetDirectory = path.resolve(baseDirectory, process.argv[2]);
        if (!fs.existsSync(targetDirectory) || !fs.statSync(targetDirectory).isDirectory()) {
            console.error('Invalid directory specified.');
            process.exit(1);
        }
    } else {
        targetDirectory = await selectFolder(baseDirectory);
    }

    if (!operationType) {
        console.error('Please specify an operation type using --type (add, del, or replace).');
        process.exit(1);
    }

    console.log(`Processing directory: ${targetDirectory}`);
    console.log(`Operation type: ${operationType}`);

    // 要件処理
    ensureTxtFiles(targetDirectory);
    const records = readTxtFiles(targetDirectory);

    const rl = readline.createInterface({
        input: process.stdin,
        output: process.stdout,
    });

    if (operationType === 'replace') {
        rl.question('Enter the target block: ', (targetBlock) => {
            rl.question('Enter the replacement block: ', (replacementBlock) => {
                const updatedRecords = replaceBlocks(targetBlock.trim(), replacementBlock.trim(), records);
                saveTxtFiles(targetDirectory, updatedRecords);
                rl.close();
            });
        });
    } else {
        rl.question('Enter comma-separated strings: ', (input) => {
            const userBlocks = input.split(',').map((block) => block.trim());

            if (operationType === 'add') {
                const updatedRecords = addBlocks(userBlocks, records);
                saveTxtFiles(targetDirectory, updatedRecords);
            } else if (operationType === 'del') {
                const updatedRecords = deleteBlocks(userBlocks, records);
                saveTxtFiles(targetDirectory, updatedRecords);
            } else {
                console.error('Invalid operation type. Use "add", "del", or "replace".');
            }

            rl.close();
        });
    }
}

main().catch((error) => {
    console.error('Error:', error);
    process.exit(1);
});