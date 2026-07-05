#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <windows.h>

#define MAX_FILES 1024
#define MAX_PATH_LEN 1024
#define BUFFER_SIZE 4096

int compareStrings(const void *a, const void *b)
{
    return strcmp(*(const char **)a, *(const char **)b);
}

int endsWithV(const char *name)
{
    size_t len = strlen(name);

    if (len < 2)
        return 0;

    return (_stricmp(name + len - 2, ".v") == 0);
}

int main(void)
{
    char exePath[MAX_PATH_LEN];
    char baseDir[MAX_PATH_LEN];
    char outputPath[MAX_PATH_LEN];
    char searchPath[MAX_PATH_LEN];
    char inputPath[MAX_PATH_LEN];

    DWORD len = GetModuleFileNameA(NULL, exePath, MAX_PATH_LEN);

    if (len == 0 || len == MAX_PATH_LEN)
    {
        printf("Failed to determine executable location.\n");
        return 1;
    }

    char *lastSlash = strrchr(exePath, '\\');

    if (!lastSlash)
    {
        printf("Invalid executable path.\n");
        return 1;
    }

    *lastSlash = '\0';
    strcpy(baseDir, exePath);

    snprintf(outputPath, MAX_PATH_LEN, "%s\\output.txt", baseDir);

    const char *folders[] =
    {
        "C:\\Vivado\\CompArch\\improvedMipsGit\\improvedMIPS\\improvedMIPS.srcs\\sim_1\\new",
        "C:\\Vivado\\CompArch\\improvedMipsGit\\improvedMIPS\\improvedMIPS.srcs\\sources_1\\new"
    };

    char *files[MAX_FILES];
    char *fullPaths[MAX_FILES];
    int fileCount = 0;

    for (int folder = 0; folder < 2; folder++)
    {
        snprintf(searchPath,
                 MAX_PATH_LEN,
                 "%s\\*.v",
                 folders[folder]);

        WIN32_FIND_DATAA findData;
        HANDLE hFind = FindFirstFileA(searchPath, &findData);

        if (hFind == INVALID_HANDLE_VALUE)
        {
            printf("Could not open:\n%s\n\n", folders[folder]);
            continue;
        }

        do
        {
            if (!(findData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY))
            {
                if (endsWithV(findData.cFileName))
                {
                    files[fileCount] = _strdup(findData.cFileName);

                    fullPaths[fileCount] = (char *)malloc(MAX_PATH_LEN);

                    if (!files[fileCount] || !fullPaths[fileCount])
                    {
                        printf("Memory allocation failed.\n");
                        return 1;
                    }

                    snprintf(fullPaths[fileCount],
                             MAX_PATH_LEN,
                             "%s\\%s",
                             folders[folder],
                             findData.cFileName);

                    fileCount++;
                }
            }

        } while (FindNextFileA(hFind, &findData));

        FindClose(hFind);
    }

    if (fileCount == 0)
    {
        printf("No .v files found.\n");
        return 1;
    }

    for (int i = 0; i < fileCount - 1; i++)
    {
        for (int j = i + 1; j < fileCount; j++)
        {
            if (_stricmp(files[i], files[j]) > 0)
            {
                char *tmp;

                tmp = files[i];
                files[i] = files[j];
                files[j] = tmp;

                tmp = fullPaths[i];
                fullPaths[i] = fullPaths[j];
                fullPaths[j] = tmp;
            }
        }
    }

    FILE *out = fopen(outputPath, "w");

    if (!out)
    {
        printf("Failed to open output.txt\n");
        return 1;
    }

    char buffer[BUFFER_SIZE];

    for (int i = 0; i < fileCount; i++)
    {
        strcpy(inputPath, fullPaths[i]);

        FILE *in = fopen(inputPath, "r");

        if (!in)
        {
            printf("Could not open %s\n", inputPath);
            free(files[i]);
            free(fullPaths[i]);
            continue;
        }

        fprintf(out, "===== %s =====\n", files[i]);

        while (fgets(buffer, BUFFER_SIZE, in))
        {
            fputs(buffer, out);
        }

        fprintf(out, "\n\n");

        fclose(in);

        free(files[i]);
        free(fullPaths[i]);
    }

    fclose(out);

    printf("Successfully copied %d Verilog file(s) into output.txt\n", fileCount);

    return 0;
}