import struct
import zlib
import os

def create_png(width, height, color, output_path):
    # color: (r, g, b)
    r, g, b = color
    raw_data = bytearray()
    for y in range(height):
        raw_data.append(0) # Filter type 0 (None)
        for x in range(width):
            raw_data.extend([r, g, b, 255])
    
    def chunk(tag, data):
        return struct.pack('>I', len(data)) + tag + data + struct.pack('>I', zlib.crc32(tag + data) & 0xffffffff)

    header = b'\x89PNG\r\n\x1a\n'
    ihdr = struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0)
    idat = zlib.compress(bytes(raw_data))
    
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, 'wb') as f:
        f.write(header)
        f.write(chunk(b'IHDR', ihdr))
        f.write(chunk(b'IDAT', idat))
        f.write(chunk(b'IEND', b''))

# Generate thumbnails
# Teal / Medical Cyan for Anatomy
create_png(400, 250, (0, 150, 160), 'assets/images/anatomy.png')
# Blue / Indigo for Physiology
create_png(400, 250, (40, 90, 180), 'assets/images/physiology.png')
# Neutral Grey for Placeholder
create_png(400, 250, (140, 150, 160), 'assets/images/placeholder.png')

print("PNG images generated successfully.")
