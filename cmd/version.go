package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
)

var versionCmd = &cobra.Command{
	Use:   "version",
	Short: "Get the version of ide",
	Long:  ``,
	PersistentPreRun: func(cmd *cobra.Command, args []string) {
	},
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Printf("ide: %s\n", Version)
	},
}

func init() {
	rootCmd.AddCommand(versionCmd)
}
