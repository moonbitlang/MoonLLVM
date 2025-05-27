

pub trait Metadata : Show {
  asMetadataEnum(Self) -> MetadataEnum;
}

pub enum MetadataEnum {
  MDString(MDString)
  MDNode(MDNode)
}

// =================================================
// MDString
// =================================================

// Only Context has ability to create MDString instances.
pub struct MDString {

  // MDString is unique. So it has an ID.
  str: String
}

pub impl Metadata for MDString with asMetadataEnum(self) {
  MDString(self)
}

pub impl Show for MDString with output(self, logger) {
  logger.write_string("!\"\{self.str}\"");
}

// =================================================
// MDNode
// =================================================

pub struct MDNode {
  // MDNode is a collection of Metadata.
  // It can contain any number of MetadataEnum.
  metadata: Array[&Metadata]
}

pub impl Metadata for MDNode with asMetadataEnum(self) {
  MDNode(self)
}

pub impl Show for MDNode with output(self, logger) {
  let metadata_strs = self.metadata.map(fn {m => m.to_string()});
  let metadata_joined = metadata_strs.join(", ");
  logger.write_string("!{\{metadata_joined}}");
}

// =================================================
// MDAttachments
// =================================================

struct MDAttachments {
  attachments: Array[(String, MDNode)]
}
