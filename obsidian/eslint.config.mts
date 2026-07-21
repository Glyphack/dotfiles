import tseslint from 'typescript-eslint';
import obsidianmd from 'eslint-plugin-obsidianmd';
import globals from 'globals';
import { globalIgnores } from 'eslint/config';

export default tseslint.config(
	globalIgnores([
		'node_modules',
		'dist',
		'test-vault',
		'esbuild.config.mjs',
		'version-bump.mjs',
		'versions.json',
		'main.js',
		'package.json',
		'package-lock.json',
		'tsconfig.json',
	]),
	{
		languageOptions: {
			globals: {
				...globals.browser,
			},
			parserOptions: {
				projectService: {
					allowDefaultProject: ['eslint.config.mts', 'manifest.json'],
				},
				tsconfigRootDir: import.meta.dirname,
				extraFileExtensions: ['.json'],
			},
		},
	},
	...obsidianmd.configs.recommended,
	{
		rules: {
			'obsidianmd/ui/sentence-case': [
				'error',
				{
					brands: ['Hugo', 'Dots'],
				},
			],
		},
	},
	{
		files: ['src/hugo-sync.ts', 'src/main.ts'],
		languageOptions: {
			globals: {
				require: 'readonly',
			},
		},
		rules: {
			'import/no-nodejs-modules': 'off',
			'@typescript-eslint/no-require-imports': 'off',
		},
	},
	{
		files: ['**/*.test.ts'],
		rules: {
			'import/no-nodejs-modules': 'off',
			'@typescript-eslint/no-floating-promises': 'off',
		},
	},
);
