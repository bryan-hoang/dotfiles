/**
 * @param {import('plop').NodePlopAPI} plop The plop API object
 */
export default function config(plop) {
  plop.setGenerator('readme', {
    description: 'Project README.md',
    prompts: [
      {
        type: 'input',
        name: 'projectName',
        message: 'Project name please',
      },
    ],
    actions: [
      {
        type: 'add',
        path: 'README.template.md',
        templateFile: 'templates/plop/README.hbs',
      },
    ],
  });
}
