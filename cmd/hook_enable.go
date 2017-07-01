package cmd

import (
	"log"

	"github.com/spf13/cobra"
)

var enableHookCmd = &cobra.Command{
	Use:   "enable",
	Short: "Enable a git hook for this ide project",
	Long:  ``,
	RunE: func(cmd *cobra.Command, args []string) error {
		for _, hook := range args {
			err := Project.EnableHook(hook)

			if err != nil {
				log.Println(err)
			} else {
				log.Printf("Hook %s enabled\n", hook)
			}
		}

		return nil
	},
}

func init() {
	hookCmd.AddCommand(enableHookCmd)
}
