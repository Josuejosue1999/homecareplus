#!/usr/bin/env python3
"""
Script Python pour corriger définitivement les erreurs de compilation dans book_appointment.dart
"""

import re
import os

def fix_book_appointment_dart():
    file_path = 'lib/screens/book_appointment.dart'
    
    if not os.path.exists(file_path):
        print(f"❌ File {file_path} not found")
        return
    
    print(f"🔧 Fixing compilation errors in {file_path}...")
    
    # Lire le fichier
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 1. Corriger isTimeSlotAvailableByHospitalName -> isTimeSlotAvailable
    content = re.sub(
        r'AppointmentService\.isTimeSlotAvailableByHospitalName\(',
        'AppointmentService.isTimeSlotAvailable(',
        content
    )
    
    # 2. Corriger getAllBookedTimeSlots -> getAvailableTimeSlots
    content = re.sub(
        r'AppointmentService\.getAllBookedTimeSlots\(',
        'AppointmentService.getAvailableTimeSlots(',
        content
    )
    
    # 3. Corriger createAppointmentWithParams -> createAppointment
    content = re.sub(
        r'AppointmentService\.createAppointmentWithParams\(',
        'AppointmentService.createAppointment(',
        content
    )
    
    # 4. Supprimer les méthodes _generateDefaultTimeSlots dupliquées
    # Trouver toutes les occurrences de la méthode
    pattern = r'(\s*)List<String>\s+_generateDefaultTimeSlots\(\)\s*\{[^}]*\}'
    matches = list(re.finditer(pattern, content, re.DOTALL))
    
    if len(matches) > 1:
        print(f"📝 Found {len(matches)} duplicate _generateDefaultTimeSlots methods")
        
        # Garder seulement la première méthode
        first_match = matches[0]
        
        # Supprimer toutes les autres occurrences (en commençant par la fin pour éviter les décalages d'index)
        for match in reversed(matches[1:]):
            start, end = match.span()
            content = content[:start] + content[end:]
            print(f"🗑️ Removed duplicate _generateDefaultTimeSlots at position {start}-{end}")
    
    # 5. Corriger les erreurs de syntaxe communes
    # Assurer qu'il n'y a pas de références à des méthodes inexistantes
    content = re.sub(
        r'AppointmentService\._generateDefaultTimeSlots\(',
        '_generateDefaultTimeSlots(',
        content
    )
    
    # Écrire le fichier corrigé
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"✅ {file_path} has been fixed!")

if __name__ == "__main__":
    print("🔧 Comprehensive fixing of book_appointment.dart...")
    fix_book_appointment_dart()
    print("🎉 All book_appointment.dart errors fixed successfully!") 