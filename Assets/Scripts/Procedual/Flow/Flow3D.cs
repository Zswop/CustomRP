//Writing by Jiayun Li
//Copyright (c) 2020

using UnityEngine;

namespace OpenCS
{
	[ExecuteAlways]
	[RequireComponent(typeof(ParticleSystem))]
    public class Flow3D : MonoBehaviour
    {
		public Vector3 offset;
		public Vector3 rotation;

		[Range(0f, 1f)]
		public float strength = 1f;

		public bool damping;

		public float frequency = 1f;

		[Range(1, 8)]
		public int octaves = 1;

		[Range(1f, 4f)]
		public float lacunarity = 2f;

		[Range(0f, 1f)]
		public float persistence = 0.5f;

		[Range(1, 3)]
		public int dimensions = 3;

		public NoiseMethodType type;

		public enum PositionType
        {
			_3D, _2D, _Fun
        }

		public PositionType positionType = PositionType._2D;

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

			if (positionType == PositionType._3D) { PositionParticles(); }
			else if(positionType == PositionType._2D) { PositionParticlesWith2DNoise(); }
			else { PositionParticlesWithFun(); }
			
			system.SetParticles(particles, particleCount);
		}

		private void PositionParticles()
		{
			Quaternion q = Quaternion.Euler(rotation);
			Quaternion qInv = Quaternion.Inverse(q);
			NoiseMethod method = Noise.noiseMethods[(int)type][dimensions - 1];
			float amplitude = damping ? strength / frequency : strength;
			for (int i = 0; i < particles.Length; i++)
			{
				Vector3 position = particles[i].position;
				Vector3 point = q * position + offset;

				NoiseSample sampleX = Noise.Sum(method, point, frequency, octaves, lacunarity, persistence);
				sampleX *= amplitude;
				sampleX.derivative = qInv * sampleX.derivative;
				point = q * new Vector3(position.x + 100f, position.y, position.z) + offset;
				NoiseSample sampleY = Noise.Sum(method, point, frequency, octaves, lacunarity, persistence);
				sampleY *= amplitude;
				sampleY.derivative = qInv * sampleY.derivative;
				point = q * new Vector3(position.x, position.y + 100f, position.z) + offset;
				NoiseSample sampleZ = Noise.Sum(method, point, frequency, octaves, lacunarity, persistence);
				sampleZ *= amplitude;
				sampleZ.derivative = qInv * sampleZ.derivative;

				Vector3 curl;
				curl.x = sampleZ.derivative.y - sampleY.derivative.z;
				curl.y = sampleX.derivative.z - sampleZ.derivative.x;
				curl.z = sampleY.derivative.x - sampleX.derivative.y;
				particles[i].velocity = curl;
			}
		}

		private void PositionParticlesWith2DNoise()
		{
			Quaternion q = Quaternion.Euler(rotation);
			Quaternion qInv = Quaternion.Inverse(q);
			NoiseMethod method = Noise.noiseMethods[(int)type][dimensions - 1];
			float amplitude = damping ? strength / frequency : strength;
			for (int i = 0; i < particles.Length; i++)
			{
				Vector3 position = particles[i].position;

				Vector3 point = q * new Vector3(position.z, position.y, position.x) + offset;
				NoiseSample sampleX = Noise.Sum(method, point, frequency, octaves, lacunarity, persistence);
				sampleX *= amplitude;
				sampleX.derivative = qInv * sampleX.derivative;
				point = q * new Vector3(position.x + 100f, position.z, position.y) + offset;
				NoiseSample sampleY = Noise.Sum(method, point, frequency, octaves, lacunarity, persistence);
				sampleY *= amplitude;
				sampleY.derivative = qInv * sampleY.derivative;
				point = q * new Vector3(position.y, position.x + 100f, position.z) + offset;
				NoiseSample sampleZ = Noise.Sum(method, point, frequency, octaves, lacunarity, persistence);
				sampleZ *= amplitude;
				sampleZ.derivative = qInv * sampleZ.derivative;

				Vector3 curl;
				curl.x = sampleZ.derivative.x - sampleY.derivative.y;
				curl.y = sampleX.derivative.x - sampleZ.derivative.y;
				curl.z = sampleY.derivative.x - sampleX.derivative.y;
				particles[i].velocity = curl;
			}
		}

		private void PositionParticlesWithFun()
		{
			Quaternion q = Quaternion.Euler(rotation);
			Quaternion qInv = Quaternion.Inverse(q);
			NoiseMethod method = Noise.noiseMethods[(int)type][dimensions - 1];
			float amplitude = damping ? strength / frequency : strength;
			for (int i = 0; i < particles.Length; i++)
			{
				Vector3 position = particles[i].position;

				Vector3 point = q * new Vector3(position.z, position.y, position.x) + offset;
				NoiseSample sampleX = Noise.Sum(method, point, frequency, octaves, lacunarity, persistence);
				sampleX *= amplitude;
				sampleX.derivative = qInv * sampleX.derivative;
				point = q * new Vector3(position.x + 100f, position.z, position.y) + offset;
				NoiseSample sampleY = Noise.Sum(method, point, frequency, octaves, lacunarity, persistence);
				sampleY *= amplitude;
				sampleY.derivative = qInv * sampleY.derivative;
				point = q * new Vector3(position.y, position.x + 100f, position.z) + offset;
				NoiseSample sampleZ = Noise.Sum(method, point, frequency, octaves, lacunarity, persistence);
				sampleZ *= amplitude;
				sampleZ.derivative = qInv * sampleZ.derivative;

				Vector3 curl;
				curl.x = sampleZ.derivative.x - sampleY.derivative.y;
				curl.y = sampleX.derivative.x - sampleZ.derivative.y + 1.0f / (1.0f + position.y);
				curl.z = sampleY.derivative.x - sampleX.derivative.y;
				particles[i].velocity = curl;
			}
		}
	}
}