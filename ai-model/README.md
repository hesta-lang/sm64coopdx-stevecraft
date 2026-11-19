# AI model upload

Place the AI-edited Blender scene at:

\`ai-model/steve_compatible.blend\`

The scene must be edited from the provided SM64CoopDX Mario character template and pass the strict checks in \`tools/validate_ai_steve_scene.py\`.

Uploading this file to the \`stevecraft-ai-model-pipeline-alpha\` branch starts the conversion workflow. The workflow exports DynOS actor source and publishes it as an Actions artifact. It only commits generated actor sources after all structural and export checks pass.
