package github

type CommitType string

const (
	NewVerCommit    CommitType = "New version"
	UpdateVerCommit CommitType = "Update version"
	AddVerCommit    CommitType = "Add version"
	RmVerCommit     CommitType = "Remove"
	NewLocaleCommit CommitType = "New locale"
)

type WinGetManifest struct {
	FileName string
	Content  string
}
