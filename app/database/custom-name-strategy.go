package database

import (
	"strings"

	"gorm.io/gorm/schema"
)

type CustomNamingStrategy struct {
	schema.NamingStrategy
	TablePrefix         string
	SingularTable       bool
	NameReplacer        schema.Replacer
	NoLowerCase         bool
	IdentifierMaxLength int
}

type Namer interface {
	schema.Namer
	TableName(table string) string
	ColumnName(table, column string) string
}

func (_ CustomNamingStrategy) TableName(table string) string {
	return strings.ToUpper(string(table[0])) + table[1:] + "s"
}

func (_ CustomNamingStrategy) ColumnName(table, column string) string {
	return strings.ToLower(string(column[0])) + column[1:]
}

// RelationshipFKName generate fk name for relation
func (_ CustomNamingStrategy) RelationshipFKName(rel schema.Relationship) string {
	return rel.Name + "_" + rel.References[0].ForeignKey.DBName + "_fkey"
}
