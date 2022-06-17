{-# LANGUAGE CPP #-}
{-# LANGUAGE OverloadedStrings #-}
#if __GLASGOW_HASKELL__ >= 702
{-# LANGUAGE Trustworthy #-}
#endif

-- |
-- Module      : Data.ByteString.Base64.URL
-- Copyright   : (c) 2012 Deian Stefan
--
-- License     : BSD-style
-- Maintainer  : Emily Pillmore <emilypi@cohomolo.gy>,
--               Herbert Valerio Riedel <hvr@gnu.org>,
--               Mikhail Glushenkov <mikhail.glushenkov@gmail.com>
-- Stability   : experimental
-- Portability : GHC
--
-- Fast and efficient encoding and decoding of base64url-encoded strings.
--
-- @since 0.1.1.0
module Data.ByteString.Base64.URL
  ( encode
  , encodeUnpadded
  , decode
  , decodePadded
  , decodeUnpadded
  , decodeLenient
  ) where

import Data.ByteString.Base64.Internal
import qualified Data.ByteString as B
import Data.ByteString.Internal (ByteString(..))
import Data.Word (Word8)
import Foreign.ForeignPtr (ForeignPtr)

-- | Encode a string into base64url form.  The result will always be a
-- multiple of 4 bytes in length.
encode :: ByteString -> ByteString
encode = encodeWith Padded (mkEncodeTable alphabet table)

-- | Encode a string into unpadded base64url form.
--
-- @since 1.1.0.0
encodeUnpadded :: ByteString -> ByteString
encodeUnpadded = encodeWith Unpadded (mkEncodeTable alphabet table)

-- | Decode a base64url-encoded string applying padding if necessary.
-- This function follows the specification in <https://datatracker.ietf.org/doc/html/rfc4648 RFC 4648>
-- and in <https://datatracker.ietf.org/doc/html/rfc7049#section-2.4.4.2 RFC 7049 2.4>
decode :: ByteString -> Either String ByteString
decode = decodeWithTable Don'tCare decodeFP

-- | Decode a padded base64url-encoded string, failing if input is improperly padded.
-- This function follows the specification in <https://datatracker.ietf.org/doc/html/rfc4648 RFC 4648>
-- and in <https://datatracker.ietf.org/doc/html/rfc7049#section-2.4.4.2 RFC 7049 2.4>
--
-- @since 1.1.0.0
decodePadded :: ByteString -> Either String ByteString
decodePadded = decodeWithTable Padded decodeFP

-- | Decode a unpadded base64url-encoded string, failing if input is padded.
-- This function follows the specification in <https://datatracker.ietf.org/doc/html/rfc4648 RFC 4648>
-- and in <https://datatracker.ietf.org/doc/html/rfc7049#section-2.4.4.2 RFC 7049 2.4>
--
-- @since 1.1.0.0
decodeUnpadded :: ByteString -> Either String ByteString
decodeUnpadded = decodeWithTable Unpadded decodeFP

-- | Decode a base64url-encoded string.  This function is lenient in
-- following the specification from
-- <https://datatracker.ietf.org/doc/html/rfc4648 RFC 4648>, and will not
-- generate parse errors no matter how poor its input.
decodeLenient :: ByteString -> ByteString
decodeLenient = decodeLenientWithTable decodeFP


alphabet :: ByteString
alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
{-# NOINLINE alphabet #-}

table :: ByteString
table = "AAABACADAEAFAGAHAIAJAKALAMANAOAPAQARASATAUAVAWAXAYAZAaAbAcAdAeAfAgAhAiAjAkAlAmAnAoApAqArAsAtAuAvAwAxAyAzA0A1A2A3A4A5A6A7A8A9A-A_BABBBCBDBEBFBGBHBIBJBKBLBMBNBOBPBQBRBSBTBUBVBWBXBYBZBaBbBcBdBeBfBgBhBiBjBkBlBmBnBoBpBqBrBsBtBuBvBwBxByBzB0B1B2B3B4B5B6B7B8B9B-B_CACBCCCDCECFCGCHCICJCKCLCMCNCOCPCQCRCSCTCUCVCWCXCYCZCaCbCcCdCeCfCgChCiCjCkClCmCnCoCpCqCrCsCtCuCvCwCxCyCzC0C1C2C3C4C5C6C7C8C9C-C_DADBDCDDDEDFDGDHDIDJDKDLDMDNDODPDQDRDSDTDUDVDWDXDYDZDaDbDcDdDeDfDgDhDiDjDkDlDmDnDoDpDqDrDsDtDuDvDwDxDyDzD0D1D2D3D4D5D6D7D8D9D-D_EAEBECEDEEEFEGEHEIEJEKELEMENEOEPEQERESETEUEVEWEXEYEZEaEbEcEdEeEfEgEhEiEjEkElEmEnEoEpEqErEsEtEuEvEwExEyEzE0E1E2E3E4E5E6E7E8E9E-E_FAFBFCFDFEFFFGFHFIFJFKFLFMFNFOFPFQFRFSFTFUFVFWFXFYFZFaFbFcFdFeFfFgFhFiFjFkFlFmFnFoFpFqFrFsFtFuFvFwFxFyFzF0F1F2F3F4F5F6F7F8F9F-F_GAGBGCGDGEGFGGGHGIGJGKGLGMGNGOGPGQGRGSGTGUGVGWGXGYGZGaGbGcGdGeGfGgGhGiGjGkGlGmGnGoGpGqGrGsGtGuGvGwGxGyGzG0G1G2G3G4G5G6G7G8G9G-G_HAHBHCHDHEHFHGHHHIHJHKHLHMHNHOHPHQHRHSHTHUHVHWHXHYHZHaHbHcHdHeHfHgHhHiHjHkHlHmHnHoHpHqHrHsHtHuHvHwHxHyHzH0H1H2H3H4H5H6H7H8H9H-H_IAIBICIDIEIFIGIHIIIJIKILIMINIOIPIQIRISITIUIVIWIXIYIZIaIbIcIdIeIfIgIhIiIjIkIlImInIoIpIqIrIsItIuIvIwIxIyIzI0I1I2I3I4I5I6I7I8I9I-I_JAJBJCJDJEJFJGJHJIJJJKJLJMJNJOJPJQJRJSJTJUJVJWJXJYJZJaJbJcJdJeJfJgJhJiJjJkJlJmJnJoJpJqJrJsJtJuJvJwJxJyJzJ0J1J2J3J4J5J6J7J8J9J-J_KAKBKCKDKEKFKGKHKIKJKKKLKMKNKOKPKQKRKSKTKUKVKWKXKYKZKaKbKcKdKeKfKgKhKiKjKkKlKmKnKoKpKqKrKsKtKuKvKwKxKyKzK0K1K2K3K4K5K6K7K8K9K-K_LALBLCLDLELFLGLHLILJLKLLLMLNLOLPLQLRLSLTLULVLWLXLYLZLaLbLcLdLeLfLgLhLiLjLkLlLmLnLoLpLqLrLsLtLuLvLwLxLyLzL0L1L2L3L4L5L6L7L8L9L-L_MAMBMCMDMEMFMGMHMIMJMKMLMMMNMOMPMQMRMSMTMUMVMWMXMYMZMaMbMcMdMeMfMgMhMiMjMkMlMmMnMoMpMqMrMsMtMuMvMwMxMyMzM0M1M2M3M4M5M6M7M8M9M-M_NANBNCNDNENFNGNHNINJNKNLNMNNNONPNQNRNSNTNUNVNWNXNYNZNaNbNcNdNeNfNgNhNiNjNkNlNmNnNoNpNqNrNsNtNuNvNwNxNyNzN0N1N2N3N4N5N6N7N8N9N-N_OAOBOCODOEOFOGOHOIOJOKOLOMONOOOPOQOROSOTOUOVOWOXOYOZOaObOcOdOeOfOgOhOiOjOkOlOmOnOoOpOqOrOsOtOuOvOwOxOyOzO0O1O2O3O4O5O6O7O8O9O-O_PAPBPCPDPEPFPGPHPIPJPKPLPMPNPOPPPQPRPSPTPUPVPWPXPYPZPaPbPcPdPePfPgPhPiPjPkPlPmPnPoPpPqPrPsPtPuPvPwPxPyPzP0P1P2P3P4P5P6P7P8P9P-P_QAQBQCQDQEQFQGQHQIQJQKQLQMQNQOQPQQQRQSQTQUQVQWQXQYQZQaQbQcQdQeQfQgQhQiQjQkQlQmQnQoQpQqQrQsQtQuQvQwQxQyQzQ0Q1Q2Q3Q4Q5Q6Q7Q8Q9Q-Q_RARBRCRDRERFRGRHRIRJRKRLRMRNRORPRQRRRSRTRURVRWRXRYRZRaRbRcRdReRfRgRhRiRjRkRlRmRnRoRpRqRrRsRtRuRvRwRxRyRzR0R1R2R3R4R5R6R7R8R9R-R_SASBSCSDSESFSGSHSISJSKSLSMSNSOSPSQSRSSSTSUSVSWSXSYSZSaSbScSdSeSfSgShSiSjSkSlSmSnSoSpSqSrSsStSuSvSwSxSySzS0S1S2S3S4S5S6S7S8S9S-S_TATBTCTDTETFTGTHTITJTKTLTMTNTOTPTQTRTSTTTUTVTWTXTYTZTaTbTcTdTeTfTgThTiTjTkTlTmTnToTpTqTrTsTtTuTvTwTxTyTzT0T1T2T3T4T5T6T7T8T9T-T_UAUBUCUDUEUFUGUHUIUJUKULUMUNUOUPUQURUSUTUUUVUWUXUYUZUaUbUcUdUeUfUgUhUiUjUkUlUmUnUoUpUqUrUsUtUuUvUwUxUyUzU0U1U2U3U4U5U6U7U8U9U-U_VAVBVCVDVEVFVGVHVIVJVKVLVMVNVOVPVQVRVSVTVUVVVWVXVYVZVaVbVcVdVeVfVgVhViVjVkVlVmVnVoVpVqVrVsVtVuVvVwVxVyVzV0V1V2V3V4V5V6V7V8V9V-V_WAWBWCWDWEWFWGWHWIWJWKWLWMWNWOWPWQWRWSWTWUWVWWWXWYWZWaWbWcWdWeWfWgWhWiWjWkWlWmWnWoWpWqWrWsWtWuWvWwWxWyWzW0W1W2W3W4W5W6W7W8W9W-W_XAXBXCXDXEXFXGXHXIXJXKXLXMXNXOXPXQXRXSXTXUXVXWXXXYXZXaXbXcXdXeXfXgXhXiXjXkXlXmXnXoXpXqXrXsXtXuXvXwXxXyXzX0X1X2X3X4X5X6X7X8X9X-X_YAYBYCYDYEYFYGYHYIYJYKYLYMYNYOYPYQYRYSYTYUYVYWYXYYYZYaYbYcYdYeYfYgYhYiYjYkYlYmYnYoYpYqYrYsYtYuYvYwYxYyYzY0Y1Y2Y3Y4Y5Y6Y7Y8Y9Y-Y_ZAZBZCZDZEZFZGZHZIZJZKZLZMZNZOZPZQZRZSZTZUZVZWZXZYZZZaZbZcZdZeZfZgZhZiZjZkZlZmZnZoZpZqZrZsZtZuZvZwZxZyZzZ0Z1Z2Z3Z4Z5Z6Z7Z8Z9Z-Z_aAaBaCaDaEaFaGaHaIaJaKaLaMaNaOaPaQaRaSaTaUaVaWaXaYaZaaabacadaeafagahaiajakalamanaoapaqarasatauavawaxayaza0a1a2a3a4a5a6a7a8a9a-a_bAbBbCbDbEbFbGbHbIbJbKbLbMbNbObPbQbRbSbTbUbVbWbXbYbZbabbbcbdbebfbgbhbibjbkblbmbnbobpbqbrbsbtbubvbwbxbybzb0b1b2b3b4b5b6b7b8b9b-b_cAcBcCcDcEcFcGcHcIcJcKcLcMcNcOcPcQcRcScTcUcVcWcXcYcZcacbcccdcecfcgchcicjckclcmcncocpcqcrcsctcucvcwcxcyczc0c1c2c3c4c5c6c7c8c9c-c_dAdBdCdDdEdFdGdHdIdJdKdLdMdNdOdPdQdRdSdTdUdVdWdXdYdZdadbdcdddedfdgdhdidjdkdldmdndodpdqdrdsdtdudvdwdxdydzd0d1d2d3d4d5d6d7d8d9d-d_eAeBeCeDeEeFeGeHeIeJeKeLeMeNeOePeQeReSeTeUeVeWeXeYeZeaebecedeeefegeheiejekelemeneoepeqereseteuevewexeyeze0e1e2e3e4e5e6e7e8e9e-e_fAfBfCfDfEfFfGfHfIfJfKfLfMfNfOfPfQfRfSfTfUfVfWfXfYfZfafbfcfdfefffgfhfifjfkflfmfnfofpfqfrfsftfufvfwfxfyfzf0f1f2f3f4f5f6f7f8f9f-f_gAgBgCgDgEgFgGgHgIgJgKgLgMgNgOgPgQgRgSgTgUgVgWgXgYgZgagbgcgdgegfggghgigjgkglgmgngogpgqgrgsgtgugvgwgxgygzg0g1g2g3g4g5g6g7g8g9g-g_hAhBhChDhEhFhGhHhIhJhKhLhMhNhOhPhQhRhShThUhVhWhXhYhZhahbhchdhehfhghhhihjhkhlhmhnhohphqhrhshthuhvhwhxhyhzh0h1h2h3h4h5h6h7h8h9h-h_iAiBiCiDiEiFiGiHiIiJiKiLiMiNiOiPiQiRiSiTiUiViWiXiYiZiaibicidieifigihiiijikiliminioipiqirisitiuiviwixiyizi0i1i2i3i4i5i6i7i8i9i-i_jAjBjCjDjEjFjGjHjIjJjKjLjMjNjOjPjQjRjSjTjUjVjWjXjYjZjajbjcjdjejfjgjhjijjjkjljmjnjojpjqjrjsjtjujvjwjxjyjzj0j1j2j3j4j5j6j7j8j9j-j_kAkBkCkDkEkFkGkHkIkJkKkLkMkNkOkPkQkRkSkTkUkVkWkXkYkZkakbkckdkekfkgkhkikjkkklkmknkokpkqkrksktkukvkwkxkykzk0k1k2k3k4k5k6k7k8k9k-k_lAlBlClDlElFlGlHlIlJlKlLlMlNlOlPlQlRlSlTlUlVlWlXlYlZlalblcldlelflglhliljlklllmlnlolplqlrlsltlulvlwlxlylzl0l1l2l3l4l5l6l7l8l9l-l_mAmBmCmDmEmFmGmHmImJmKmLmMmNmOmPmQmRmSmTmUmVmWmXmYmZmambmcmdmemfmgmhmimjmkmlmmmnmompmqmrmsmtmumvmwmxmymzm0m1m2m3m4m5m6m7m8m9m-m_nAnBnCnDnEnFnGnHnInJnKnLnMnNnOnPnQnRnSnTnUnVnWnXnYnZnanbncndnenfngnhninjnknlnmnnnonpnqnrnsntnunvnwnxnynzn0n1n2n3n4n5n6n7n8n9n-n_oAoBoCoDoEoFoGoHoIoJoKoLoMoNoOoPoQoRoSoToUoVoWoXoYoZoaobocodoeofogohoiojokolomonooopoqorosotouovowoxoyozo0o1o2o3o4o5o6o7o8o9o-o_pApBpCpDpEpFpGpHpIpJpKpLpMpNpOpPpQpRpSpTpUpVpWpXpYpZpapbpcpdpepfpgphpipjpkplpmpnpopppqprpsptpupvpwpxpypzp0p1p2p3p4p5p6p7p8p9p-p_qAqBqCqDqEqFqGqHqIqJqKqLqMqNqOqPqQqRqSqTqUqVqWqXqYqZqaqbqcqdqeqfqgqhqiqjqkqlqmqnqoqpqqqrqsqtquqvqwqxqyqzq0q1q2q3q4q5q6q7q8q9q-q_rArBrCrDrErFrGrHrIrJrKrLrMrNrOrPrQrRrSrTrUrVrWrXrYrZrarbrcrdrerfrgrhrirjrkrlrmrnrorprqrrrsrtrurvrwrxryrzr0r1r2r3r4r5r6r7r8r9r-r_sAsBsCsDsEsFsGsHsIsJsKsLsMsNsOsPsQsRsSsTsUsVsWsXsYsZsasbscsdsesfsgshsisjskslsmsnsospsqsrssstsusvswsxsyszs0s1s2s3s4s5s6s7s8s9s-s_tAtBtCtDtEtFtGtHtItJtKtLtMtNtOtPtQtRtStTtUtVtWtXtYtZtatbtctdtetftgthtitjtktltmtntotptqtrtstttutvtwtxtytzt0t1t2t3t4t5t6t7t8t9t-t_uAuBuCuDuEuFuGuHuIuJuKuLuMuNuOuPuQuRuSuTuUuVuWuXuYuZuaubucudueufuguhuiujukulumunuoupuqurusutuuuvuwuxuyuzu0u1u2u3u4u5u6u7u8u9u-u_vAvBvCvDvEvFvGvHvIvJvKvLvMvNvOvPvQvRvSvTvUvVvWvXvYvZvavbvcvdvevfvgvhvivjvkvlvmvnvovpvqvrvsvtvuvvvwvxvyvzv0v1v2v3v4v5v6v7v8v9v-v_wAwBwCwDwEwFwGwHwIwJwKwLwMwNwOwPwQwRwSwTwUwVwWwXwYwZwawbwcwdwewfwgwhwiwjwkwlwmwnwowpwqwrwswtwuwvwwwxwywzw0w1w2w3w4w5w6w7w8w9w-w_xAxBxCxDxExFxGxHxIxJxKxLxMxNxOxPxQxRxSxTxUxVxWxXxYxZxaxbxcxdxexfxgxhxixjxkxlxmxnxoxpxqxrxsxtxuxvxwxxxyxzx0x1x2x3x4x5x6x7x8x9x-x_yAyByCyDyEyFyGyHyIyJyKyLyMyNyOyPyQyRySyTyUyVyWyXyYyZyaybycydyeyfygyhyiyjykylymynyoypyqyrysytyuyvywyxyyyzy0y1y2y3y4y5y6y7y8y9y-y_zAzBzCzDzEzFzGzHzIzJzKzLzMzNzOzPzQzRzSzTzUzVzWzXzYzZzazbzczdzezfzgzhzizjzkzlzmznzozpzqzrzsztzuzvzwzxzyzzz0z1z2z3z4z5z6z7z8z9z-z_0A0B0C0D0E0F0G0H0I0J0K0L0M0N0O0P0Q0R0S0T0U0V0W0X0Y0Z0a0b0c0d0e0f0g0h0i0j0k0l0m0n0o0p0q0r0s0t0u0v0w0x0y0z000102030405060708090-0_1A1B1C1D1E1F1G1H1I1J1K1L1M1N1O1P1Q1R1S1T1U1V1W1X1Y1Z1a1b1c1d1e1f1g1h1i1j1k1l1m1n1o1p1q1r1s1t1u1v1w1x1y1z101112131415161718191-1_2A2B2C2D2E2F2G2H2I2J2K2L2M2N2O2P2Q2R2S2T2U2V2W2X2Y2Z2a2b2c2d2e2f2g2h2i2j2k2l2m2n2o2p2q2r2s2t2u2v2w2x2y2z202122232425262728292-2_3A3B3C3D3E3F3G3H3I3J3K3L3M3N3O3P3Q3R3S3T3U3V3W3X3Y3Z3a3b3c3d3e3f3g3h3i3j3k3l3m3n3o3p3q3r3s3t3u3v3w3x3y3z303132333435363738393-3_4A4B4C4D4E4F4G4H4I4J4K4L4M4N4O4P4Q4R4S4T4U4V4W4X4Y4Z4a4b4c4d4e4f4g4h4i4j4k4l4m4n4o4p4q4r4s4t4u4v4w4x4y4z404142434445464748494-4_5A5B5C5D5E5F5G5H5I5J5K5L5M5N5O5P5Q5R5S5T5U5V5W5X5Y5Z5a5b5c5d5e5f5g5h5i5j5k5l5m5n5o5p5q5r5s5t5u5v5w5x5y5z505152535455565758595-5_6A6B6C6D6E6F6G6H6I6J6K6L6M6N6O6P6Q6R6S6T6U6V6W6X6Y6Z6a6b6c6d6e6f6g6h6i6j6k6l6m6n6o6p6q6r6s6t6u6v6w6x6y6z606162636465666768696-6_7A7B7C7D7E7F7G7H7I7J7K7L7M7N7O7P7Q7R7S7T7U7V7W7X7Y7Z7a7b7c7d7e7f7g7h7i7j7k7l7m7n7o7p7q7r7s7t7u7v7w7x7y7z707172737475767778797-7_8A8B8C8D8E8F8G8H8I8J8K8L8M8N8O8P8Q8R8S8T8U8V8W8X8Y8Z8a8b8c8d8e8f8g8h8i8j8k8l8m8n8o8p8q8r8s8t8u8v8w8x8y8z808182838485868788898-8_9A9B9C9D9E9F9G9H9I9J9K9L9M9N9O9P9Q9R9S9T9U9V9W9X9Y9Z9a9b9c9d9e9f9g9h9i9j9k9l9m9n9o9p9q9r9s9t9u9v9w9x9y9z909192939495969798999-9_-A-B-C-D-E-F-G-H-I-J-K-L-M-N-O-P-Q-R-S-T-U-V-W-X-Y-Z-a-b-c-d-e-f-g-h-i-j-k-l-m-n-o-p-q-r-s-t-u-v-w-x-y-z-0-1-2-3-4-5-6-7-8-9---__A_B_C_D_E_F_G_H_I_J_K_L_M_N_O_P_Q_R_S_T_U_V_W_X_Y_Z_a_b_c_d_e_f_g_h_i_j_k_l_m_n_o_p_q_r_s_t_u_v_w_x_y_z_0_1_2_3_4_5_6_7_8_9_-__"
{-# NOINLINE table #-}

decodeFP :: ForeignPtr Word8
#if MIN_VERSION_bytestring(0,11,0)
BS decodeFP _ =
#else
PS decodeFP _ _ =
#endif
  B.pack $ replicate 45 x
    ++ [62,x,x]
    ++ [52..61]
    ++ [x,x,x,done,x,x,x]
    ++ [0..25]
    ++ [x,x,x,x,63,x]
    ++ [26..51]
    ++ replicate 133 x

{-# NOINLINE decodeFP #-}

x :: Integral a => a
x = 255
{-# INLINE x #-}
