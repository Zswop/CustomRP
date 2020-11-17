using UnityEngine;
using UnityEditor;

namespace OpenCS
{
    [CanEditMultipleObjects]
    [CustomEditor(typeof(CustomAdditinalCameraData))]
    public class CustomAdditinalCameraDataEditor : Editor
    {
        public override void OnInspectorGUI()
        {
        }
    }

    [CustomEditorForRenderPipeline(typeof(Camera), typeof(CustomRenderPipelineAsset))]
    public class CustomCameraEditor : CameraEditor
    {
        private CustomAdditinalCameraData additionalCameraData;
        private SerializedObject additionalCameraDataSO;
        SerializedProperty postProcessingSP;

        internal class Styles
        {
            public static GUIContent postProcessing = EditorGUIUtility.TrTextContent("Post Processing", "Enable this to make this camera render post-processing effects.");
        }

        public Camera camera { get { return target as Camera; } }

        void Init(CustomAdditinalCameraData additionalCameraData)
        {
            if (additionalCameraData == null) { return; }

            this.additionalCameraData = additionalCameraData;
            additionalCameraDataSO = new SerializedObject(additionalCameraData);
            postProcessingSP = additionalCameraDataSO.FindProperty("postProcessing");
        }

        public new void OnEnable()
        {
            settings.OnEnable();
            additionalCameraData = camera.gameObject.GetComponent<CustomAdditinalCameraData>();
            if (additionalCameraData == null){
                additionalCameraData = camera.gameObject.AddComponent<CustomAdditinalCameraData>();
            }
            Init(additionalCameraData);
        }

        public override void OnInspectorGUI()
        {
            base.OnInspectorGUI();
            DrawPostProcessing();
        }

        void DrawPostProcessing()
        {
            bool selectedRenderPostProcessing = false;
            if (additionalCameraDataSO != null)
            {
                additionalCameraDataSO.Update();
                selectedRenderPostProcessing = postProcessingSP.boolValue;
            }

            if (DrawToggle(postProcessingSP, ref selectedRenderPostProcessing, Styles.postProcessing))
            {
                if (additionalCameraDataSO == null) 
                {
                    var additionalCameraData = Undo.AddComponent<CustomAdditinalCameraData>(camera.gameObject);
                    Init(additionalCameraData);
                }

                postProcessingSP.boolValue = selectedRenderPostProcessing;
                additionalCameraDataSO.ApplyModifiedProperties();
            }
        }

        bool DrawToggle(SerializedProperty sp, ref bool value, GUIContent style)
        {
            var controlRect = EditorGUILayout.GetControlRect(true);
            if (additionalCameraDataSO != null) { 
                EditorGUI.BeginProperty(controlRect, style, sp);
            }

            bool changed = false;
            EditorGUI.BeginChangeCheck();
            value = EditorGUI.Toggle(controlRect, style, value);
            if (EditorGUI.EndChangeCheck()) { changed = true; }

            if (additionalCameraDataSO != null){
                EditorGUI.EndProperty();
            }
            return changed;
        }
    }
}