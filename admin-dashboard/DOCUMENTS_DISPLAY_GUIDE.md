# Guide d'affichage des documents - Admin Dashboard

## Nouvelles fonctionnalités ajoutées

### 1. Section Documents de Certificat
Sur la page `/clinic-profile/[id]`, une nouvelle section affiche les documents de certificat des hôpitaux.

#### Caractéristiques :
- **Affichage des informations** : Nom du fichier, type, taille, date d'upload
- **Indicateur de stockage** : Montre si le document est stocké en base (Database) ou dans le cloud (Cloud Storage)
- **Bouton de visualisation** : Permet d'ouvrir le document dans un modal
- **Design responsive** : S'adapte à tous les écrans

### 2. Section Documents Additionnels
Affiche les documents ID/Passport et autres documents supplémentaires.

#### Types de documents supportés :
- **ID/Passport** : Documents d'identité (badge vert)
- **Documents additionnels** : Autres documents (badge orange)

### 3. Modal de visualisation
Un modal moderne permet de visualiser les documents directement dans l'interface.

#### Fonctionnalités du modal :
- **Aperçu des images** : Affichage direct des fichiers JPG, PNG, etc.
- **Aperçu des PDFs** : Intégration native des fichiers PDF
- **Bouton de téléchargement** : Permet de télécharger le document
- **Interface intuitive** : Navigation facile avec boutons de contrôle

### 4. Gestion des formats
Le système gère automatiquement différents formats de fichiers :
- **Images** : JPG, PNG, GIF, etc.
- **PDFs** : Affichage intégré
- **Autres formats** : Message informatif avec option de téléchargement

## Structure des données

Les documents sont stockés dans la structure suivante :
```javascript
{
  documents: {
    certificate: {
      fileName: "certificate.pdf",
      fileType: "application/pdf",
      fileSize: 123456,
      fileData: "base64_encoded_data",
      uploadedAt: "2025-07-12T20:00:00Z",
      storageMethod: "firestore"
    },
    id: {
      fileName: "id_passport.jpg",
      fileType: "image/jpeg",
      fileSize: 654321,
      fileData: "base64_encoded_data",
      uploadedAt: "2025-07-12T20:00:00Z",
      storageMethod: "firestore"
    },
    additional: {
      fileName: "additional_doc.pdf",
      fileType: "application/pdf",
      fileSize: 987654,
      fileData: "base64_encoded_data",
      uploadedAt: "2025-07-12T20:00:00Z",
      storageMethod: "firestore"
    }
  }
}
```

## Styles CSS ajoutés

### Classes principales :
- `.document-section` : Conteneur des documents
- `.document-item` : Style de chaque document
- `.document-info` : Informations du document
- `.document-actions` : Boutons d'action
- `.document-empty` : Message quand aucun document

### Effets visuels :
- Hover effects sur les documents
- Badges colorés par type de document
- Animations de transition
- Design cohérent avec l'interface existante

## Utilisation

1. **Accéder au profil d'une clinique** : `/clinic-profile/[clinic_id]`
2. **Voir les documents** : Les sections apparaissent automatiquement si des documents existent
3. **Visualiser un document** : Cliquer sur le bouton "View"
4. **Télécharger un document** : Utiliser le bouton "Download" dans le modal

## Sécurité

- Les documents sont chargés de manière sécurisée
- Validation des types de fichiers
- Gestion des erreurs de chargement
- Protection contre les injections XSS

## Compatibilité

- Compatible avec tous les navigateurs modernes
- Responsive design pour mobile et desktop
- Intégration avec Bootstrap 5
- Utilisation de Font Awesome pour les icônes

---

*Guide créé le 12 juillet 2025* 