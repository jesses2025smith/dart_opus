use std::fs::File;
use std::io::{Read as _, Write as _};
use std::ptr;

use anyhow::{anyhow, Ok};
use opus_ffi::decoder::{decode, free_decoder, new_decoder};
use opus_ffi::encoder::{encode, free_encoder, new_encoder};
use opus_ffi::error::OpusError;
use opus_rs::{Decoder, Encoder};

const FRAME_SIZE: usize = 80;
const CHANNELS: u32 = 1;
const SAMPLE_RATE: u32 = 16000;
const APPLICATION: u32 = 1;

#[test]
fn test_decode() -> anyhow::Result<()> {
    let mut file = File::open("data/R20250728-151607.opus")?;
    let output_path = "data/R20250728-151607(decode).pcm";
    let mut output_file = File::create(output_path)?;

    let mut decoder: *mut Decoder = ptr::null_mut();
    // Allocate OpusError on heap because free_opus_error expects it
    let mut error = OpusError {
        code: 0,
        message: ptr::null_mut(),
    };

    // Initialize decoder: 16kHz, 1 channel
    let res = new_decoder(CHANNELS, SAMPLE_RATE, &mut decoder, &mut error);
    assert_eq!(res, 0);
    assert!(!decoder.is_null());

    let mut buffer = [0u8; FRAME_SIZE]; // 80 bytes input chunk
                                                // Max frame size for Opus is 120ms. At 16kHz, 120ms = 1920 samples.
                                                // We allocate enough space to avoid OPUS_BUFFER_TOO_SMALL if the packet contains more than 20ms.
    let mut output_buffer = [0i16; FRAME_SIZE * 4];
    let mut decoded_samples: usize = 0;
    let mut total_decoded_samples = 0;

    loop {
        // Use read_exact to ensure we get a full chunk.
        // If we get EOF (UnexpectedEof), we stop.
        if let Err(e) = file.read_exact(&mut buffer) {
            if e.kind() == std::io::ErrorKind::UnexpectedEof {
                break;
            }
            return Err(e.into());
        }

        let res = decode(
            decoder,
            buffer.as_ptr(),
            buffer.len() as u32,
            output_buffer.as_mut_ptr(),
            output_buffer.len() as u32,
            false,
            &mut decoded_samples,
            &mut error,
        );

        if res < 0 {
            return Err(anyhow!("Decode error: {}", res));
        }

        total_decoded_samples += decoded_samples;

        // Write to output file (raw PCM, 16-bit LE)
        let output_bytes = unsafe {
            std::slice::from_raw_parts(
                output_buffer.as_ptr() as *const u8,
                decoded_samples * 2, // 2 bytes per sample
            )
        };
        output_file.write_all(output_bytes)?;
    }

    println!("Total decoded samples: {}", total_decoded_samples);

    // Cleanup
    free_decoder(decoder);

    Ok(())
}

#[test]
fn test_encode() -> anyhow::Result<()> {
    let output_filename = "data/R20250728-151607(encode).opus";
    let mut output_file = File::create(output_filename)?;
    // We need a PCM file. Assuming the one from test_decode exists or user provided one.
    // User snippet used: "data/R20250728-151607(decode).pcm"
    let mut file = File::open("data/R20250728-151607(decode).pcm")?;

    let mut encoder: *mut Encoder = ptr::null_mut();
    let mut error = OpusError {
        code: 0,
        message: ptr::null_mut(),
    };

    // Initialize encoder: 1 channel, 16kHz, Application::Voip (1)
    let res = new_encoder(CHANNELS, SAMPLE_RATE, APPLICATION, &mut encoder, &mut error);
    assert_eq!(res, 0);
    assert!(!encoder.is_null());

    // 20ms frame at 16kHz = 80 samples.
    // 16-bit PCM = 2 bytes per sample.
    // Input buffer size = 80 * 2 = 160 bytes.
    const PCM_FRAME_SIZE: usize = FRAME_SIZE * 4;
    let mut pcm_buffer = [0u8; PCM_FRAME_SIZE];
    let mut output_buffer = [0u8; 1024]; // Max Opus packet is smaller than this
    let mut encoded_len: usize = 0;

    loop {
        // Read PCM data
        if let Err(e) = file.read_exact(&mut pcm_buffer) {
            if e.kind() == std::io::ErrorKind::UnexpectedEof {
                break;
            }
            return Err(e.into());
        }

        // Convert u8 buffer to i16 pointer
        // input_size should be number of samples (i16 elements), not bytes
        // PCM_FRAME_SIZE is in bytes, so divide by 2 to get number of i16 samples
        let input_ptr = pcm_buffer.as_ptr() as *const i16;
        let input_samples = PCM_FRAME_SIZE / 2; // Convert bytes to samples (i16 = 2 bytes)

        let res = encode(
            encoder,
            input_ptr,
            input_samples as u32,
            output_buffer.as_mut_ptr(),
            output_buffer.len() as u32,
            &mut encoded_len,
            &mut error,
        );

        if res < 0 {
            return Err(anyhow!("Encode error: {}", res));
        }

        println!("Encoded size: {}", encoded_len);

        // Write encoded data to file
        // Note: Raw Opus file usually needs framing (like Ogg) to be playable.
        // Here we just write raw packets which might not be directly playable but verifies the encoder.
        // For a proper test we might want to write length-delimited packets or just verify it produces data.
        output_file.write_all(&output_buffer[..encoded_len])?;
    }

    // Cleanup
    free_encoder(encoder);

    Ok(())
}
