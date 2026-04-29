import type { Plugin } from "@opencode-ai/plugin";

export const InjectEnvPlugin: Plugin = async () => {
	return {
		"shell.env": async (_input, output) => {
			// Don't report progress in coding agent's noninteractive output windows.
			output.env.HK_TERMINAL_PROGRESS = "0";
		},
	};
};
