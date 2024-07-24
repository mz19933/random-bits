Downlod ffmpeg -
https://www.gyan.dev/ffmpeg/builds/
1) list available devices
ffmpeg-2024-07-22-git-172da370e7-full_build\bin>ffmpeg -list_devices true -f dshow -i dummy
2) no limit(ctrl+c to finish) recording using microphone
ffmpeg -f dshow -i audio="Microphone (Logitech Wireless Headset)" output.wav
3)30-second audio segment using your "Microphone (Logitech Wireless Headset)"
ffmpeg -f dshow -i audio="Microphone (Logitech Wireless Headset)" -t 30 output.wav

# pip install openai-whisper torch torchvision torchaudio
import torch
import whisper

# Load the Whisper-small model
model = whisper.load_model("small")

# Load and preprocess the audio file
audio = whisper.load_audio("output.wav")

# Perform the transcription
result = model.transcribe(audio, language="he")

# Print the transcription result
print(result["text"])
