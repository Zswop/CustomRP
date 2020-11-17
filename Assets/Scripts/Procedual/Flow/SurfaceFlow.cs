//Writing by Jiayun Li
//Copyright (c) 2020

using UnityEngine;

namespace OpenCS
{
	[ExecuteAlways]
	[RequireComponent(typeof(ParticleSystem))]
	public class SurfaceFlow : MonoBehaviour
	{
		public SurfaceCreator surface;
		public float flowStrength = 0.01f;

		private ParticleSystem system;
		private ParticleSystem.Particle[] particles;

		private void LateUpdate()
		{
			if (system == null)
			{
				system = GetComponent<ParticleSystem>();
			}
			int maxParticles = system.main.maxParticles;
			if (particles == null || particles.Length < maxParticles)
			{
				particles = new ParticleSystem.Particle[maxParticles];
			}
			int particleCount = system.GetParticles(particles);
			PositionParticles();
			system.SetParticles(particles, particleCount);
		}

		private void PositionParticles()
		{
			Quaternion q = Quaternion.Euler(surface.rotation);
			Quaternion qInv = Quaternion.Inverse(q);
			NoiseMethod method = Noise.noiseMethods[(int)surface.type][surface.dimensions - 1];
			float amplitude = surface.damping ? surface.strength / surface.frequency : surface.strength;
			var startSize = system.main.startSizeMultiplier;
			for (int i = 0; i < particles.Length; i++)
			{
				Vector3 position = particles[i].position;
				Vector3 point = q * new Vector3(position.x, position.z) + surface.offset;
				NoiseSample sample = Noise.Sum(method, point, surface.frequency, surface.octaves, surface.lacunarity, surface.persistence);
				sample = surface.type == NoiseMethodType.Value ? (sample - 0.5f) : (sample * 0.5f);
				sample *= amplitude;
				sample.derivative = qInv * sample.derivative;

				Vector3 curl = new Vector3(sample.derivative.y, 0f, -sample.derivative.x);
				position += curl * Time.deltaTime * flowStrength;
				//position += sample.derivative * Time.deltaTime * flowStrength;
				position.y = sample.value + startSize;
				particles[i].position = position;

				// clamp
				if (position.x < -0.5f || position.x > 0.5f || position.z < -0.5f || position.z > 0.5f)
				{
					particles[i].remainingLifetime = 0f;
				}
			}
		}
	}
}