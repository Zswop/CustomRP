//Writing by Jiayun Li
//Copyright (c) 2020

using UnityEngine;
using UnityEditor;

namespace OpenCS
{
    [CanEditMultipleObjects]
    [CustomEditor(typeof(CustomAdditionalCameraData))]
    public class CustomAdditinalCameraDataEditor : Editor
    {
        public override void OnInspectorGUI()
        {
            base.OnInspectorGUI();
        }
    }

    [CustomEditorForRenderPipeline(typeof(Camera), typeof(CustomRenderPipelineAsset))]
    public class CustomCameraEditor : CameraEditor
    {
        private CustomAdditionalCameraData additionalCameraData;
        private SerializedObject additionalCameraDataSO;
        SerializedProperty postProcessingSP;

        internal class Styles
        {
            public static GUIContent postProcessing = EditorGUIUtility.TrTextContent("Post Processing", "Enable this to make this camera render post-processing effects.");
        }

        public Camera camera { get { return target as Camera; } }

        void Init(CustomAdditionalCameraData additionalCameraData)
        {
            if (additionalCameraData == null) { return; }

            this.additionalCameraData = additionalCameraData;
            additionalCameraDataSO = new SerializedObject(additionalCameraData);
            postProcessingSP = additionalCameraDataSO.FindProperty("postProcessing");
        }

        public new void OnEnable()
        {
            settings.OnEnable();
            additionalCameraData = camera.gameObject.GetComponent<CustomAdditionalCameraData>();
            if (additionalCameraData == null){
                additionalCameraData = camera.gameObject.AddComponent<CustomAdditionalCameraData>();
            }
            Init(additionalCameraData);
        }

        //public override void OnInspectorGUI()
        //{
        //    base.OnInspectorGUI();
        //    DrawPostProcessing();
        //}

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
                    var additionalCameraData = Undo.AddComponent<CustomAdditionalCameraData>(camera.gameObject);
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